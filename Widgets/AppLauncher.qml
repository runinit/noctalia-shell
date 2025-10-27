import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as QQC2
import Quickshell
import qs.Commons
import qs.Services
import qs.Widgets
import "../Helpers/fzf.js" as FzfLib

// Shared app launcher component used by both bar popout and spotlight modal
Item {
  id: root

  // View mode: "list" or "grid"
  property string viewMode: "list"

  // Selected category ("All" by default)
  property string selectedCategory: "All"

  // Show categories selector
  property bool showCategories: true

  // Grid columns (for grid mode)
  property int gridColumns: 4

  // Icon size range - increased for better visibility
  property int minIconSize: 40
  property int maxIconSize: 72
  property int defaultIconSize: 56

  // Signals
  signal appLaunched(string appKey)
  signal closed()

  // Search state
  property string searchQuery: ""
  property var searchResults: []
  property int selectedIndex: -1

  // Focus handling
  property alias searchFieldFocus: searchField.focus

  function focusSearch() {
    searchField.forceActiveFocus()
  }

  function clearSearch() {
    searchQuery = ""
    selectedIndex = -1
  }

  // Search function using two-stage algorithm
  function performSearch(query) {
    const apps = AppSearchService.getApplicationsByCategory(selectedCategory)

    if (!query || query.trim() === "") {
      // No query - show all apps sorted by usage
      searchResults = sortAppsByUsage(apps)
      return
    }

    const q = query.trim().toLowerCase()

    // Stage 1: Exact matching with priority scores
    const exactMatches = []
    for (let i = 0; i < apps.length; i++) {
      const app = apps[i]
      const name = (app.name || "").toLowerCase()
      const execName = (app.executableName || "").toLowerCase()
      const comment = (app.comment || "").toLowerCase()

      let score = 0

      // Exact name match
      if (name === q) {
        score = 10000
      }
      // Name contains as word
      else if (name.includes(" " + q + " ") || name.startsWith(q + " ") || name.endsWith(" " + q)) {
        score = 9500 + (100 - Math.min(name.length, 100))
      }
      // Name starts with query
      else if (name.startsWith(q)) {
        score = 9000 + (100 - Math.min(name.length, 100))
      }
      // Word in name starts with query
      else if (name.includes(" " + q)) {
        score = 8500 + (100 - Math.min(name.length, 100))
      }
      // Name contains query
      else if (name.includes(q)) {
        score = 8000 + (100 - Math.min(name.length, 100))
      }
      // Executable name matches
      else if (execName === q || execName.startsWith(q)) {
        score = 7500
      }
      // Comment contains query
      else if (comment.includes(q)) {
        score = 7000
      }

      if (score > 0) {
        // Add usage bonus
        const appKey = AppSearchService.getAppKey(app)
        const usageScore = AppUsageHistoryData.getUsageScore(appKey)
        score += usageScore

        exactMatches.push({ app: app, score: score })
      }
    }

    // If we have exact matches, use those
    if (exactMatches.length > 0) {
      exactMatches.sort((a, b) => b.score - a.score)
      searchResults = exactMatches.slice(0, 50).map(m => m.app)
      return
    }

    // Stage 2: Fuzzy matching fallback
    try {
      const fzfResults = performFuzzySearch(query, apps)
      searchResults = fzfResults.slice(0, 50)
    } catch (e) {
      Logger.w("AppLauncher", "Fuzzy search failed:", e)
      // Fallback to simple substring match
      searchResults = apps.filter(app => {
        const text = app.searchableText || ""
        return text.includes(q)
      }).slice(0, 50)
    }
  }

  // Fuzzy search using fzf.js library
  function performFuzzySearch(query, apps) {
    // Prepare items for fzf
    const items = apps.map(app => ({
      name: app.name || "",
      comment: app.comment || "",
      executableName: app.executableName || "",
      app: app
    }))

    // Create finder instance
    const finder = new FzfLib.Finder(items, {
      selector: item => `${item.name} ${item.comment} ${item.executableName}`,
      casing: FzfLib.CaseSensitive.CASE_INSENSITIVE
    })

    // Perform search
    const results = finder.find(query)

    // Extract apps with usage bonus
    return results.map(result => {
      const app = result.item.app
      const appKey = AppSearchService.getAppKey(app)
      const usageScore = AppUsageHistoryData.getUsageScore(appKey)

      // Combine fzf score (capped at 2000) with usage score
      const totalScore = Math.min(result.score, 2000) + usageScore

      return { app: app, score: totalScore }
    }).sort((a, b) => b.score - a.score).map(item => item.app)
  }

  // Sort apps by usage (for empty search)
  function sortAppsByUsage(apps) {
    return apps.slice().sort((a, b) => {
      const keyA = AppSearchService.getAppKey(a)
      const keyB = AppSearchService.getAppKey(b)

      const scoreA = AppUsageHistoryData.getUsageScore(keyA)
      const scoreB = AppUsageHistoryData.getUsageScore(keyB)

      if (scoreB !== scoreA) {
        return scoreB - scoreA
      }

      // Alphabetical fallback
      return (a.name || "").localeCompare(b.name || "")
    })
  }

  // Launch app
  function launchApp(app) {
    if (!app) return

    const appKey = AppSearchService.getAppKey(app)

    // Record usage
    AppUsageHistoryData.recordLaunch(appKey)

    // Execute app
    AppSearchService.executeApp(app)

    // Emit signal
    appLaunched(appKey)
  }

  // Keyboard navigation
  function navigateDown() {
    if (selectedIndex < searchResults.length - 1) {
      selectedIndex++
      ensureVisible(selectedIndex)
    }
  }

  function navigateUp() {
    if (selectedIndex > 0) {
      selectedIndex--
      ensureVisible(selectedIndex)
    }
  }

  function navigateLeft() {
    if (viewMode === "grid" && selectedIndex > 0) {
      selectedIndex = Math.max(0, selectedIndex - 1)
      ensureVisible(selectedIndex)
    }
  }

  function navigateRight() {
    if (viewMode === "grid" && selectedIndex < searchResults.length - 1) {
      selectedIndex = Math.min(searchResults.length - 1, selectedIndex + 1)
      ensureVisible(selectedIndex)
    }
  }

  function ensureVisible(index) {
    // Let the view handle scrolling
    if (viewMode === "list") {
      listView.positionViewAtIndex(index, ListView.Contain)
    } else {
      gridView.positionViewAtIndex(index, GridView.Contain)
    }
  }

  function activateSelected() {
    if (selectedIndex >= 0 && selectedIndex < searchResults.length) {
      launchApp(searchResults[selectedIndex])
    }
  }

  // Watch for search changes
  onSearchQueryChanged: {
    performSearch(searchQuery)
    selectedIndex = -1
  }

  onSelectedCategoryChanged: {
    performSearch(searchQuery)
    selectedIndex = -1
  }

  Component.onCompleted: {
    // Initial search
    performSearch("")
  }

  // UI Layout
  ColumnLayout {
    anchors.fill: parent
    spacing: Style.marginM

    // Search and categories in a single card for better Material 3 cohesion
    NBox {
      Layout.fillWidth: true
      implicitHeight: searchAndCategoriesColumn.implicitHeight + Style.marginM * 2

      ColumnLayout {
        id: searchAndCategoriesColumn
        anchors.fill: parent
        anchors.margins: Style.marginM
        spacing: Style.marginL

        // Search field
        NTextInput {
          id: searchField
          Layout.fillWidth: true
          Layout.preferredHeight: Style.baseWidgetSize
          placeholderText: I18n.tr("app-launcher.search-placeholder")
          text: searchQuery

          onTextChanged: {
            searchQuery = text
          }

          Keys.onPressed: (event) => {
            if (event.key === Qt.Key_Down || (event.key === Qt.Key_J && event.modifiers & Qt.ControlModifier)) {
              navigateDown()
              event.accepted = true
            } else if (event.key === Qt.Key_Up || (event.key === Qt.Key_K && event.modifiers & Qt.ControlModifier)) {
              navigateUp()
              event.accepted = true
            } else if (event.key === Qt.Key_Left || (event.key === Qt.Key_H && event.modifiers & Qt.ControlModifier)) {
              navigateLeft()
              event.accepted = true
            } else if (event.key === Qt.Key_Right || (event.key === Qt.Key_L && event.modifiers & Qt.ControlModifier)) {
              navigateRight()
              event.accepted = true
            } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
              activateSelected()
              event.accepted = true
            } else if (event.key === Qt.Key_Escape) {
              closed()
              event.accepted = true
            } else if (event.key === Qt.Key_Tab) {
              if (event.modifiers & Qt.ShiftModifier) {
                navigateUp()
              } else {
                navigateDown()
              }
              event.accepted = true
            }
          }
        }

        // Category selector
        Flow {
          id: categoryFlow
          Layout.fillWidth: true
          visible: showCategories
          spacing: Style.marginS

          Repeater {
            model: AppSearchService.getCategories()

            Rectangle {
              width: categoryText.implicitWidth + Style.marginM * 2
              height: Style.baseWidgetSize * 0.7
              radius: Style.radiusS

              property bool isSelected: selectedCategory === modelData.name
              property bool hovered: false

              color: isSelected ? Color.mPrimary : (hovered ? Color.mTertiary : Color.transparent)

              Behavior on color {
                ColorAnimation {
                  duration: Style.animationFast
                }
              }

              NText {
                id: categoryText
                anchors.centerIn: parent
                text: modelData.displayName
                pointSize: Style.fontSizeS
                font.weight: Style.fontWeightMedium
                color: parent.isSelected ? Color.mOnPrimary : (parent.hovered ? Color.mOnTertiary : Color.mOnSurface)

                Behavior on color {
                  ColorAnimation {
                    duration: Style.animationFast
                  }
                }
              }

              MouseArea {
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onEntered: parent.hovered = true
                onExited: parent.hovered = false
                onClicked: selectedCategory = modelData.name
              }
            }
          }
        }
      }
    }

    // Results area in a card
    NBox {
      Layout.fillWidth: true
      Layout.fillHeight: true

      Item {
        anchors.fill: parent
        anchors.margins: Style.marginM

      // List view
      NListView {
        id: listView
        anchors.fill: parent
        visible: viewMode === "list"
        clip: true

        model: searchResults

        delegate: QQC2.ItemDelegate {
          width: listView.width
          height: 60

          highlighted: index === selectedIndex

          onClicked: {
            selectedIndex = index
            launchApp(modelData)
          }

          background: Rectangle {
            color: parent.highlighted ? Color.mSecondaryContainer : (parent.hovered ? Color.mSurfaceVariant : Color.transparent)
            radius: Style.radiusM

            // Material 3 selection border similar to settings panels
            border.color: parent.highlighted ? Color.mPrimary : (parent.hovered ? Color.mTertiary : Color.transparent)
            border.width: parent.highlighted ? Style.borderM : (parent.hovered ? Style.borderS : 0)

            Behavior on color {
              ColorAnimation {
                duration: Style.animationFast
              }
            }

            Behavior on border.color {
              ColorAnimation {
                duration: Style.animationFast
              }
            }

            Behavior on border.width {
              NumberAnimation {
                duration: Style.animationFast
              }
            }
          }

          contentItem: RowLayout {
            spacing: Style.marginM

            Image {
              Layout.preferredWidth: 40
              Layout.preferredHeight: 40
              source: "image://icon/" + (modelData.icon || "application-x-executable")
              sourceSize.width: 40
              sourceSize.height: 40
              smooth: true
              asynchronous: true
            }

            ColumnLayout {
              Layout.fillWidth: true
              spacing: 2

              NText {
                Layout.fillWidth: true
                text: modelData.name || "Unknown"
                font.weight: Font.Medium
                color: Color.mOnSurface
                elide: Text.ElideRight
              }

              NText {
                Layout.fillWidth: true
                text: modelData.comment || modelData.genericName || ""
                font.pixelSize: Style.fontSizeXS
                color: Color.mOnSurfaceVariant
                elide: Text.ElideRight
              }
            }
          }
        }
      }

      // Grid view
      GridView {
        id: gridView
        anchors.fill: parent
        visible: viewMode === "grid"
        clip: true

        cellWidth: width / gridColumns
        cellHeight: cellWidth * 1.05  // Tighter aspect ratio

        model: searchResults

        delegate: QQC2.ItemDelegate {
          width: gridView.cellWidth - Style.marginXS  // Tighter spacing
          height: gridView.cellHeight - Style.marginXS

          highlighted: index === selectedIndex

          onClicked: {
            selectedIndex = index
            launchApp(modelData)
          }

          background: Rectangle {
            color: parent.highlighted ? Color.mSecondaryContainer : (parent.hovered ? Color.mSurfaceVariant : Color.transparent)
            radius: Style.radiusM

            // Material 3 selection border similar to settings panels
            border.color: parent.highlighted ? Color.mPrimary : (parent.hovered ? Color.mTertiary : Color.transparent)
            border.width: parent.highlighted ? Style.borderM : (parent.hovered ? Style.borderS : 0)

            Behavior on color {
              ColorAnimation {
                duration: Style.animationFast
              }
            }

            Behavior on border.color {
              ColorAnimation {
                duration: Style.animationFast
              }
            }

            Behavior on border.width {
              NumberAnimation {
                duration: Style.animationFast
              }
            }
          }

          contentItem: ColumnLayout {
            anchors.centerIn: parent
            spacing: Style.marginXS  // Tighter spacing

            Image {
              Layout.alignment: Qt.AlignHCenter
              Layout.preferredWidth: defaultIconSize
              Layout.preferredHeight: defaultIconSize
              source: "image://icon/" + (modelData.icon || "application-x-executable")
              sourceSize.width: defaultIconSize
              sourceSize.height: defaultIconSize
              smooth: true
              asynchronous: true
            }

            NText {
              Layout.alignment: Qt.AlignHCenter
              Layout.preferredWidth: parent.width - Style.marginS * 2
              text: modelData.name || "Unknown"
              font.pixelSize: Style.fontSizeL  // Larger text for better readability
              font.weight: Style.fontWeightMedium
              color: Color.mOnSurface
              elide: Text.ElideRight
              horizontalAlignment: Text.AlignHCenter
              wrapMode: Text.WordWrap
              maximumLineCount: 2
            }
          }
        }
      }
      }
    }
  }
}

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

  // Icon size range
  property int minIconSize: 32
  property int maxIconSize: 64
  property int defaultIconSize: 48

  // Signals
  signal appLaunched(string appKey)
  signal closed()

  // Search state
  property string searchQuery: ""
  property var searchResults: []
  property int selectedIndex: 0

  // Focus handling
  property alias searchFieldFocus: searchField.focus

  function focusSearch() {
    searchField.forceActiveFocus()
  }

  function clearSearch() {
    searchQuery = ""
    selectedIndex = 0
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
    selectedIndex = 0
  }

  onSelectedCategoryChanged: {
    performSearch(searchQuery)
    selectedIndex = 0
  }

  Component.onCompleted: {
    // Initial search
    performSearch("")
  }

  // UI Layout
  ColumnLayout {
    anchors.fill: parent
    spacing: Style.marginM

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

    // Category selector (optional)
    Row {
      Layout.fillWidth: true
      spacing: Style.marginS
      visible: showCategories

      Repeater {
        model: AppSearchService.getCategories()

        NButton {
          text: modelData.displayName
          highlighted: selectedCategory === modelData.name
          onClicked: selectedCategory = modelData.name
        }
      }
    }

    // Results area
    Item {
      Layout.fillWidth: true
      Layout.fillHeight: true

      // List view
      NListView {
        id: listView
        anchors.fill: parent
        visible: viewMode === "list"

        model: searchResults

        delegate: ItemDelegate {
          width: listView.width
          height: 60

          highlighted: index === selectedIndex

          onClicked: {
            selectedIndex = index
            launchApp(modelData)
          }

          contentItem: RowLayout {
            spacing: Style.marginM

            NIcon {
              Layout.preferredWidth: 40
              Layout.preferredHeight: 40
              source: modelData.icon || "application-x-executable"
              iconColor: Color.mOnSurface
            }

            ColumnLayout {
              Layout.fillWidth: true
              spacing: 2

              NText {
                Layout.fillWidth: true
                text: modelData.name || "Unknown"
                font.weight: Font.Medium
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

        cellWidth: width / gridColumns
        cellHeight: cellWidth * 1.2

        model: searchResults

        delegate: ItemDelegate {
          width: gridView.cellWidth
          height: gridView.cellHeight

          highlighted: index === selectedIndex

          onClicked: {
            selectedIndex = index
            launchApp(modelData)
          }

          contentItem: ColumnLayout {
            anchors.centerIn: parent
            spacing: Style.marginS

            NIcon {
              Layout.alignment: Qt.AlignHCenter
              Layout.preferredWidth: defaultIconSize
              Layout.preferredHeight: defaultIconSize
              source: modelData.icon || "application-x-executable"
              iconColor: Color.mOnSurface
            }

            NText {
              Layout.alignment: Qt.AlignHCenter
              Layout.preferredWidth: parent.width - Style.marginM * 2
              text: modelData.name || "Unknown"
              font.pixelSize: Style.fontSizeS
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

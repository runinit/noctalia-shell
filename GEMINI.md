## Project Overview

Noctalia Shell is a lightweight, customizable desktop environment for Wayland compositors, built with QML and the Quickshell framework. It offers a visually appealing and minimalist user experience with a focus on theming and personalization. The shell integrates with popular Wayland compositors like Hyprland and Niri to provide a seamless desktop experience.

The project is structured into several modules, including:

*   **`Modules`**: Contains the core UI components of the shell, such as the bar, dock, launcher, and notification center.
*   **`Services`**: Provides the backend logic for interacting with the system, including services for managing themes, audio, network, and more.
*   **`Commons`**: Includes common QML components and utilities used throughout the application.
*   **`Widgets`**: A collection of custom widgets used to build the user interface.

## Building and Running

The project uses the Nix package manager to manage dependencies and provide a reproducible development environment. To build and run the Noctalia shell, you will need to have Nix installed on your system.

**Build and Run:**

To enter a development shell with all the necessary dependencies, run the following command at the root of the project:

```bash
nix develop
```

Once inside the shell, you can run the Noctalia shell with the following command:

```bash
noctalia-shell
```

**Configuration:**

The main configuration file for the shell is located at `~/.config/noctalia/settings.json`. This file allows you to customize various aspects of the shell, including the theme, bar, and other modules.

## Development Conventions

The project follows a modular architecture, with a clear separation between the UI components and the backend services. The code is written in QML and JavaScript, with a focus on readability and maintainability.

**Coding Style:**

The project uses a consistent coding style, with a focus on clear and concise code. The QML files are well-structured and easy to follow, with a clear separation of concerns.

**Theming:**

Theming is a core feature of the Noctalia shell. The `AppThemeService` is responsible for managing the color scheme of the shell and other applications. It can generate a color palette from the current wallpaper using `matugen` or use a predefined theme.

**Services:**

The shell uses a service-based architecture to interact with the system. Each service is responsible for a specific functionality, such as managing audio, network, or themes. This modular approach makes it easy to add new features and integrations to the shell.

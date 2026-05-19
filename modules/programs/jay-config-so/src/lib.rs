use jay_config::{
    config,
    input::get_default_seat,
    keyboard::{
        mods::{LOGO, SHIFT},
        syms::*,
    },
    video::{on_connector_connected, on_connector_disconnected, Connector},
    Direction, Workspace,
};

/// Connectors that should auto-disable when their monitor powers off
/// (e.g. a TV that drops DRM connection when turned off).
const AUTO_TOGGLE_CONNECTORS: &[&str] = &["DP-2"];

/// Check if a workspace has any windows (is occupied).
fn workspace_has_windows(ws: Workspace) -> bool {
    let root = ws.window();
    root.exists() && !root.children().is_empty()
}

/// Find the best fallback workspace on a connector, preferring occupied ones.
/// Returns None if there are no other workspaces.
fn find_occupied_fallback(connector: Connector, exclude: Workspace) -> Option<Workspace> {
    let workspaces = connector.workspaces();
    // Prefer occupied workspace
    workspaces
        .iter()
        .find(|ws| **ws != exclude && workspace_has_windows(**ws))
        .or_else(|| workspaces.iter().find(|ws| **ws != exclude))
        .copied()
}

/// Move current workspace to output in direction, then:
/// 1. Show an occupied fallback on the source output
/// 2. Focus the moved workspace on the destination output
fn smart_move_to_output(direction: Direction) {
    let seat = get_default_seat();
    let current_ws = seat.get_keyboard_workspace();
    if !current_ws.exists() {
        return;
    }
    let source = current_ws.connector();
    if !source.exists() {
        return;
    }
    // Try requested direction first; if no output there, try opposite (wrap)
    let dest = source.connector_in_direction(direction);
    let dest = if dest.exists() {
        dest
    } else {
        let opposite = match direction {
            Direction::Left => Direction::Right,
            Direction::Right => Direction::Left,
            Direction::Up => Direction::Down,
            Direction::Down => Direction::Up,
        };
        let wrapped = source.connector_in_direction(opposite);
        if !wrapped.exists() {
            return;
        }
        wrapped
    };

    // Find a good fallback for the source output before the move
    let fallback = find_occupied_fallback(source, current_ws);

    // Move the workspace
    current_ws.move_to_output(dest);

    // Show the fallback on source (if any occupied workspace remains)
    if let Some(fb) = fallback {
        seat.show_workspace_on(fb, source);
    }

    // Focus the moved workspace on destination
    seat.show_workspace(current_ws);
}

fn configure() {
    // Load the TOML config first (all existing config applies)
    jay_toml_config::configure();

    let seat = get_default_seat();

    // Override move-to-output bindings with smart versions
    seat.bind(LOGO | SYM_o, || smart_move_to_output(Direction::Right));
    seat.bind(LOGO | SHIFT | SYM_o, || {
        smart_move_to_output(Direction::Left)
    });

    on_connector_connected(|c| {
        if AUTO_TOGGLE_CONNECTORS.contains(&c.name().as_str()) {
            c.set_enabled(true);
        }
    });
    on_connector_disconnected(|c| {
        if AUTO_TOGGLE_CONNECTORS.contains(&c.name().as_str()) {
            c.set_enabled(false);
        }
    });
}

config!(configure);

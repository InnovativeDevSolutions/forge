//! Terrain SVG export functionality via FFI to external C++ library.
//!
//! Provides commands to export terrain data to SVG format with various
//! rendering options (location names, grid, contour lines, etc.).

use arma_rs::Group;

#[cfg(target_os = "windows")]
mod windows_ffi {
    use std::os::raw::{c_char, c_void};

    #[link(name = "kernel32")]
    unsafe extern "system" {
        pub(super) fn GetModuleHandleA(lpModuleName: *const u8) -> *mut c_void;
        pub(super) fn GetProcAddress(hModule: *mut c_void, lpProcName: *const u8) -> *mut c_void;
    }

    pub(super) const EXPORT_SVG_PROC_NAME: &[u8] = b"?ExportSVG@@YAXPEBD_N11111@Z\0";

    pub(super) type FnExportSVG =
        extern "system" fn(*const c_char, bool, bool, bool, bool, bool, bool) -> *const c_void;
}

/// Creates the Arma 3 command group for the terrain module.
///
/// Registers the `exportSVG` command with the Arma 3 extension.
pub fn group() -> Group {
    Group::new().command("exportSVG", export_svg)
}

/// Exports terrain data to an SVG file with configurable rendering options.
///
/// # Parameters
/// - `file_path`: Output SVG file path
/// - `draw_location_names`: Include location/place names
/// - `draw_grid`: Include grid overlay
/// - `draw_contourlines`: Include elevation contour lines
/// - `draw_tree_objects`: Include vegetation/tree objects
/// - `draw_mountain_heightpoints`: Include mountain peak elevation markers
/// - `simple_roads`: Use simplified road rendering
///
/// # Returns
/// - `Ok(())` on success
/// - `Err(String)` with error message on failure
#[cfg(target_os = "windows")]
pub fn export_terrain_svg(
    file_path: String,
    draw_location_names: bool,
    draw_grid: bool,
    draw_contourlines: bool,
    draw_tree_objects: bool,
    draw_mountain_heightpoints: bool,
    simple_roads: bool,
) -> Result<(), String> {
    unsafe {
        use windows_ffi::*;

        let module = GetModuleHandleA(std::ptr::null());
        if module.is_null() {
            return Err("Failed to get game engine module handle".to_string());
        }

        let export_svg_proc = GetProcAddress(module, EXPORT_SVG_PROC_NAME.as_ptr());
        if export_svg_proc.is_null() {
            return Err("Failed to find ExportSVG function in game engine".to_string());
        }

        let export_svg: FnExportSVG = std::mem::transmute(export_svg_proc);
        let file_path_cstr =
            std::ffi::CString::new(file_path).map_err(|e| format!("Invalid file path: {}", e))?;

        export_svg(
            file_path_cstr.as_ptr(),
            draw_location_names,
            draw_grid,
            draw_contourlines,
            draw_tree_objects,
            draw_mountain_heightpoints,
            simple_roads,
        );

        Ok(())
    }
}

#[cfg(not(target_os = "windows"))]
pub fn export_terrain_svg(
    _file_path: String,
    _draw_location_names: bool,
    _draw_grid: bool,
    _draw_contourlines: bool,
    _draw_tree_objects: bool,
    _draw_mountain_heightpoints: bool,
    _simple_roads: bool,
) -> Result<(), String> {
    Err("Terrain SVG export is only available on Windows".to_string())
}

#[derive(serde::Deserialize)]
#[serde(rename_all = "camelCase")]
struct ExportSvgOptions {
    file_path: String,
    #[serde(default)]
    draw_location_names: bool,
    #[serde(default)]
    draw_grid: bool,
    #[serde(default)]
    draw_contourlines: bool,
    #[serde(default)]
    draw_tree_objects: bool,
    #[serde(default)]
    draw_mountain_heightpoints: bool,
    #[serde(default)]
    simple_roads: bool,
}

/// Arma command handler for terrain SVG export.
///
/// # SQF Usage
/// ```sqf
/// // Register callback handler (optional, for async result)
/// ["terrain:exportSVG", {
///     params ["_response"];
///     systemChat format ["Export %1: %2",
///         _response get "status",
///         _response get "message"
///     ];
/// }] call forge_x_extension_fnc_setHandler;
///
/// // Create options and call extension
/// private _options = createHashMapFromArray [
///     ["filePath", "C:\terrain.svg"],
///     ["drawLocationNames", true],
///     ["drawGrid", true],
///     ["drawContourlines", true],
///     ["drawTreeObjects", false],
///     ["drawMountainHeightpoints", true],
///     ["simpleRoads", false]
/// ];
///
/// ["terrain:exportSVG", [toJSON _options]] call forge_x_extension_fnc_extCall;
/// ```
fn export_svg(options_json: String) -> String {
    let options: ExportSvgOptions = match serde_json::from_str(&options_json) {
        Ok(opts) => opts,
        Err(e) => {
            return serde_json::json!({
                "status": "error",
                "message": format!("Invalid JSON options: {}", e)
            })
            .to_string();
        }
    };

    match export_terrain_svg(
        options.file_path,
        options.draw_location_names,
        options.draw_grid,
        options.draw_contourlines,
        options.draw_tree_objects,
        options.draw_mountain_heightpoints,
        options.simple_roads,
    ) {
        Ok(_) => serde_json::json!({
            "status": "success",
            "message": "Terrain exported successfully"
        })
        .to_string(),
        Err(e) => serde_json::json!({
            "status": "error",
            "message": e
        })
        .to_string(),
    }
}

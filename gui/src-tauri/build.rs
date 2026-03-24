fn main() {
    // Only run tauri_build when building the tauri-app feature
    #[cfg(feature = "tauri-app")]
    tauri_build::build();
}

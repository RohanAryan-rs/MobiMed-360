{{flutter_js}}
{{flutter_build_config}}
// Own service worker is registered in index.html; omit Flutter's generated
// worker settings so two workers do not compete for the same scope.
const config = { canvasKitBaseUrl: 'canvaskit/' };
_flutter.loader.load({
  config,
  onEntrypointLoaded: async initializer => {
    try {
      const runner = await initializer.initializeEngine(config);
      await runner.runApp();
      document.getElementById('app-loading')?.remove();
    } catch {
      const loading = document.getElementById('app-loading');
      if (loading) loading.textContent = 'Unable to open MobiMed. Please reload and try again.';
    }
  }
});

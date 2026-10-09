{{flutter_js}}
{{flutter_build_config}}

// No serviceWorkerSettings: Flutter's own worker is a self-unregistering stub.
// Offline support comes from service_worker.js, which
// tool/generate_service_worker.dart writes into build/web after the build.
_flutter.loader.load();

if ('serviceWorker' in navigator) {
  window.addEventListener('load', () => {
    navigator.serviceWorker
      .register('service_worker.js')
      .catch((error) => console.warn('Service worker not registered:', error));
  });
}

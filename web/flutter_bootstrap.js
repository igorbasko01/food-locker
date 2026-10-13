{{flutter_js}}
{{flutter_build_config}}

// Loads without Flutter's own worker, which is a self-unregistering stub.
// Offline support comes from service_worker.js, which
// tool/generate_service_worker.dart writes into build/web after the build.
_flutter.loader.load();

if ('serviceWorker' in navigator) {
  // Without a controller at startup this is the first install, whose takeover
  // brings nothing new; afterwards a takeover means a newer deploy, which
  // lib/core/app_updates_web.dart offers to reload into.
  const hadController = navigator.serviceWorker.controller !== null;
  navigator.serviceWorker.addEventListener('controllerchange', () => {
    if (!hadController) return;
    window.foodLockerUpdateReady = true;
    window.dispatchEvent(new Event('foodlocker-update-ready'));
  });

  window.addEventListener('load', () => {
    navigator.serviceWorker
      .register('service_worker.js')
      .then((registration) => {
        // An installed app can sit in the background for days without a
        // navigation, the only time the browser checks for a new worker.
        document.addEventListener('visibilitychange', () => {
          if (document.visibilityState === 'visible') registration.update();
        });
      })
      .catch((error) => console.warn('Service worker not registered:', error));
  });
}

# Pendientes de publicación

## Antes de TestFlight

- [x] Configurar en `AppLinks.configured` el correo de soporte, la web y el ID real de App Store (`6834888121`). Comprobados con HTTP 200 la web, la política de privacidad y la ficha de la app (2026-11-24).
- [x] Política de privacidad publicada y términos mediante la EULA estándar de Apple; ambos enlaces configurados y responden (2026-11-24).
- [x] La ficha pública de App Store indica «No se recopilan datos»; confirmar que la respuesta sigue coincidiendo con la build enviada.
- [x] Incluir `PrivacyInfo.xcprivacy` con `NSPrivacyAccessedAPICategoryUserDefaults` (`CA92.1`) por el uso de `UserDefaults` en `AppSession`; verificado que se copia a la raíz del bundle.
- [ ] Preparar y revisar las capturas de pantalla para los tamaños de dispositivo compatibles.
- [x] Nombre público elegido: «Presupuestos Para Autónomos», visible en App Store y en el nombre localizado de la app.
- [x] Plan por defecto ilimitado en la v1 (`StubEntitlements`, con test en `ReleaseConfigurationTests`).
- [x] Esquema SwiftData actual validado con los tests de migración incluidos en la suite (2026-11-24); 1.0.2 no añade cambios de esquema.

## Antes de enviar a App Store

- [x] Confirmar que el correo, la web, la política, los términos y el identificador de App Store están configurados en la app y que sus enlaces públicos responden.
- [ ] Revisar en App Store Connect las capturas para iPhone/iPad, los idiomas/metadatos de las 7 localizaciones, la ficha de privacidad, la clasificación por edad y la configuración de plan para la build 1.0.2 (build 3).
- [ ] Crear y validar un archive firmado para distribución App Store; la compilación Release local no firma ni sube el binario.

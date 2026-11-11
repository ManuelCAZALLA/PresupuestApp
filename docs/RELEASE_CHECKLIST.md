# Pendientes de publicación

## Antes de TestFlight

- [ ] Sustituir en `AppLinks.configured` los valores provisionales: `soporte@presupuestapp.example`, `https://example.com/presupuestapp` y `appStoreID = "0000000000"`. Verificado el 2026-11-11: la URL de privacidad actual devuelve 404.
- [ ] Publicar la política de privacidad y los términos de uso y verificar sus enlaces desde Ajustes.
- [ ] Completar el cuestionario de privacidad en App Store Connect.
- [ ] Preparar y revisar las capturas de pantalla para los tamaños de dispositivo compatibles.
- [ ] Elegir el nombre definitivo de la app y aplicarlo a los metadatos y textos de marca.
- [x] Plan por defecto ilimitado en la v1 (`StubEntitlements`, con test en `ReleaseConfigurationTests`).
- [ ] Congelar el esquema SwiftData definitivo, incluidos los campos añadidos para el PDF, y comprobar la migración desde el esquema anterior.

## Antes de enviar a App Store

- [ ] Confirmar que el correo, el sitio web, la política, los términos y el identificador de App Store son los definitivos y funcionan.
- [ ] Revisar que las capturas, el nombre, la ficha de privacidad y la configuración de plan coinciden con la versión que se va a enviar.

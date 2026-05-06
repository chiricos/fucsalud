# Plan de Implementación Futura: Drupal E2E Test Manager

Este documento detalla la hoja de ruta para la evolución del skill, ampliando sus capacidades de testing y frameworks soportados.

---

## 🚀 Próximos Pasos (Playwright)

### 1. Webforms Complejos
- **Objetivo**: Soporte para formularios con múltiples páginas (Wizard), lógica condicional visible/oculta y campos de subida de archivos.
- **Implementación**: Mejorar `paso-05-modelado.sh` para detectar estados del Wizard y generar flujos de `await page.click('.next-button')`.

### 2. Testing de Autenticación
- **Objetivo**: Generar tests para Login, recuperación de contraseña y áreas privadas de usuarios (roles específicos).
- **Implementación**: Crear un script de generación de `storageState.json` para reutilizar sesiones autenticadas y evitar logins repetitivos.

### 3. Testing de Performance y Accesibilidad
- **Objetivo**: Integrar checks automáticos de Lighthouse o Axe-core dentro del flujo de Playwright.
- **Implementación**: Añadir dependencias `@axe-core/playwright` y generar assertions de accesibilidad.

### 4. Visual Regression Testing
- **Objetivo**: Detectar cambios visuales inesperados (CSS/Layout) tras actualizaciones.
- **Implementación**: Generar tests con `expect(page).toHaveScreenshot()`.

---

## 🎭 Integración de Cypress

### Fase 1: Arquitectura Dual
- **Objetivo**: Permitir al usuario elegir entre Playwright y Cypress en la Fase 3.
- **Implementación**: Crear carpeta `tests/cypress` y adaptar el script de setup (`paso-02`) para instalar Cypress si se selecciona.

### Fase 2: Traducción de Modelos
- **Objetivo**: Reutilizar el JSON generado en `paso-05-modelado.sh` para crear archivos `.cy.js`.
- **Implementación**: Crear `paso-06b-generacion-cypress.sh` que mapee el modelo a comandos `cy.get().type()`.

---

## 🛠️ Mejoras de Infraestructura

- **Detección Automática de Nodos**: Implementar lógica robusta en los scripts para encontrar automáticamente en qué `/node/XXX` está incrustado un webform si el acceso directo está deshabilitado.
- **MCP Playwright avanzado**: Mejorar la interacción con el servidor MCP para permitir "live debugging" de los tests generados.
- **CI/CD Readiness**: Generar archivos de configuración de GitHub Actions listos para correr estos tests en cada PR.

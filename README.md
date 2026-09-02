# CRM Área de Picnic — Prototipo

CRM web (prototipo) para la librería online **Área de Picnic**
(`tiendadeareadepicnic.mitiendanube.com`), conectada al catálogo público de la
tienda (precios, stock, disponibilidad, fotos) con soporte opcional de la API
privada Tienda Nube v1 para pedidos y clientes reales.

Sitio publicado (GitHub Pages): https://smarin10-bit.github.io/area-de-picnic-crm/

## Archivos

| Archivo | Descripción |
|---|---|
| `crm-area-de-picnic.html` | CRM completa en un solo archivo (HTML + CSS + JS, sin dependencias) |
| `index.html` | Copia idéntica, servida en la raíz por GitHub Pages |
| `crm-area-de-picnic.txt` | Copia idéntica en formato `.txt` (entrega solicitada) |
| `datos/snapshot-productos.json` | Snapshot del catálogo público de la tienda, regenerado por GitHub Actions |
| `scripts/sync-catalogo.ps1` | Script que lee el catálogo público (JSON-LD) y regenera el snapshot |
| `.github/workflows/sync-catalogo.yml` | Workflow que ejecuta el script cada 30 min y publica el snapshot si cambió |
| `snippet-crm-tienda.txt` | Guía para enlazar la CRM desde el menú de la tienda |
| `snippet-sin-stock-tienda.txt` | CSS para mostrar "Sin Stock" debajo del precio en la tienda (Tienda Nube) |

> `index.html` y `crm-area-de-picnic.txt` son copias de `crm-area-de-picnic.html`.
> Después de editar la CRM, volver a copiar el archivo sobre los otros dos.

## Cuenta admin (creada automáticamente en la primera ejecución)

- Usuario: **admin**
- Contraseña: **admin123**

La cuenta se crea con el primer arranque. Se cambia en **Configuración → Cuenta
admin**.

## Cómo ejecutarla

1. Abrí `crm-area-de-picnic.html` con un doble clic (funciona offline; el
   catálogo se actualiza igual desde el snapshot del repositorio) **o**
2. Servila como página (recomendado): GitHub Pages (Branch `main`, carpeta
   raíz), Netlify / Vercel, o un servidor estático local.

## Funciones

- **Dashboard:** ingresos, pedidos, ticket promedio, clientes, stock (incluye
  cantidad de títulos sin stock), top productos, canales, ventas por temática y
  registro del conector.
- **Productos organizados por temática:** la tabla agrupa el catálogo en
  **Viajes** (El País en Tero: Jujuy, Litoral 2da edición, Puerto Madryn),
  **Familia** (Hay equipo ¡a cocinar!, Antonia y el Luno, ¡No te olvides
  Antonia!, La semana de Antonia) y **Cocina** (La biblia y el Bodegón, Huevo
  Tito en el bodegón, Hay equipo ¡a cocinar!). Un título puede estar en más de
  una temática. Los títulos no listados quedan en "Sin temática asignada" y la
  temática de cualquier producto se edita desde **Editar** (casillas). Filtros
  por temática y por stock (bajo / sin stock / no activos).
- **Rótulo "Sin Stock":** cuando un producto tiene 0 unidades disponibles (o
  la tienda lo marca `OutOfStock`) se muestra **Sin Stock** debajo del precio,
  en color `#e13030`, tipografía **Instrument Sans** (Google Fonts) y tamaño
  **11 px** (clase `.sin-stock`). Para replicarlo en la tienda pública ver
  `snippet-sin-stock-tienda.txt`.
- **Clientes vinculados por email:** cada cliente tiene **nombre**,
  **apellido** y **email registrado**; el email es la clave que asocia al
  cliente con sus pedidos (los importados desde la API de la tienda se vinculan
  por email y no se duplican). La ficha permite editar nombre/apellido/email y
  valida emails repetidos.
- **Análisis del historial de compras:** por cada cliente la CRM calcula, a
  partir de los pedidos no cancelados, la distribución de temáticas (Viajes /
  Familia / Cocina), el título más comprado, unidades, gasto, última compra,
  canal habitual y sugerencias de títulos de su temática preferida que todavía
  no compró. La columna **Preferencias** resume la temática destacada y la
  ficha muestra barras, títulos comprados, sugerencias e historial completo.
  Exportación CSV con nombre, apellido, email y preferencias.
- **Pedidos:** alta, cambio de estado, canal, importación desde la API privada.
- **Configuración:** conector (modo, intervalo, URL del snapshot), token API,
  exportación CSV/JSON, importación de respaldo, cuenta admin.

Los datos viven en `localStorage` del navegador (prototipo sin servidor) y son
exportables/restaurables en JSON. Las bases guardadas por versiones anteriores
se migran automáticamente al abrir la CRM (temáticas, nombre/apellido, etc.).

## Conexión con la tienda (cómo funciona la sincronización)

Los navegadores bloquean por CORS la lectura directa de `mitiendanube.com`, y
los proxies CORS públicos que usaba la versión anterior dejaron de funcionar.
Por eso el conector ahora funciona así:

1. **GitHub Actions** (`.github/workflows/sync-catalogo.yml`) ejecuta cada 30
   minutos `scripts/sync-catalogo.ps1`, que descarga
   `https://tiendadeareadepicnic.mitiendanube.com/productos`, extrae los bloques
   JSON-LD (`schema.org/Product`: nombre, precio, moneda, stock,
   disponibilidad, foto) y, **solo si el catálogo cambió**, actualiza
   `datos/snapshot-productos.json` con un commit.
2. La CRM descarga ese archivo desde
   `https://raw.githubusercontent.com/SMarin10-bit/area-de-picnic-crm/main/datos/snapshot-productos.json`
   (permite CORS, funciona incluso abriendo el HTML con doble clic) o, como
   respaldo, desde el mismo sitio donde está publicada. El intervalo de
   sincronización se configura en **Configuración** (60 s por defecto) y
   también arranca al iniciar sesión.
3. En modo **auto** la CRM intenta además, en segundo plano, una lectura en vivo
   por proxies públicos; si alguno responde, actualiza los datos al instante.
   Su estado se ve en Configuración.

Modos disponibles: `auto` (snapshot + en vivo), `solo snapshot`, `directo`
(requiere un servidor con CORS habilitado).

### Requisitos en GitHub (una sola vez)

- **Actions habilitadas** en el repositorio (pestaña *Actions*).
- **Settings → Actions → General → Workflow permissions → "Read and write
  permissions"**, para que el workflow pueda hacer commit del snapshot (el
  workflow además declara `permissions: contents: write`).
- Para forzar una sincronización inmediata: *Actions → "Sincronizar catálogo de
  la tienda" → Run workflow*.
- GitHub pausa los workflows programados si el repositorio no tiene actividad
  durante 60 días; se reactivan desde la pestaña Actions.

Ejecución manual del script (Windows PowerShell o pwsh):

```bash
powershell -ExecutionPolicy Bypass -File scripts/sync-catalogo.ps1
```

### Base privada (pedidos/clientes reales)

En **Configuración → API privada**, pegá el `access_token` de una app creada en
`https://developers.tiendanube.com` para importar pedidos y clientes reales
(`GET /v1/orders`). Los clientes importados se vinculan por email.

## Conectar la tienda con la CRM (menú público)

La tienda es un SaaS (Tienda Nube): agregá en **Admin de la tienda → Diseño →
Menú** un enlace externo **"CRM"** apuntando a la URL publicada del prototipo
(ver `snippet-crm-tienda.txt`). Para el rótulo "Sin Stock" en la tienda, pegá el
CSS de `snippet-sin-stock-tienda.txt` en el editor de CSS avanzado del tema.

---

*Prototipo v2 — catálogo público real de tiendadeareadepicnic.mitiendanube.com
(11 productos), organizado por temáticas, con clientes vinculados por email,
análisis de preferencias y conector vía GitHub Actions.*

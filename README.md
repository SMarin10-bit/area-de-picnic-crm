# CRM Área de Picnic — Prototipo

CRM web (prototipo) para la librería online **Área de Picnic**
(`tiendadeareadepicnic.mitiendanube.com`), conectada a la base de datos pública
de la tienda (catálogo en vivo: precios, stock, disponibilidad, fotos) en tiempo
real, con soporte opcional de la API privada Tienda Nube v1 para pedidos y
clientes reales.

## Archivos

| Archivo | Descripción |
|---|---|
| `crm-area-de-picnic.html` | CRM completa en un solo archivo (HTML + CSS + JS, sin dependencias) |
| `crm-area-de-picnic.txt` | Ídem en formato `.text` (entrega solicitada) |
| `datos/snapshot-productos.json` | Captura del catálogo público real (sincronización inicial) |
| `snippet-crm-tienda.txt` | Snippet/guía para enlazar la CRM desde el menú de la tienda |

## Cuenta admin (creada automáticamente en la primera ejecución)

- Usuario: **admin**
- Contraseña: **admin123**

La cuenta se crea con el primer arranque. Se cambia en **Configuración → Cuenta
admin**.

## Cómo ejecutarla

1. Abrí `crm-area-de-picnic.html` con un doble clic (funciona 100% offline) **o**
2. Servila como página (recomendado para producción):
   - **GitHub Pages**: subí la carpeta a un repo, activá Pages (Branch `main`,
     carpeta raíz) y listo.
   - **Netlify / Vercel**: arrastrá la carpeta.
   - Local: `npx serve .` o cualquier servidor estático.

## Conexión en tiempo real con la tienda

- **Base de datos pública (automática):** la CRM lee el catálogo público
  `https://tiendadeareadepicnic.mitiendanube.com/productos` (JSON-LD embebido con
  nombre, precio ARS, stock, disponibilidad y foto) y sincroniza por polling con
  el intervalo configurado (por defecto 60 s). Verás indicador de estado
  (En línea / Caché) y el registro del conector en Dashboard.
- **Base de datos privada (pedidos/clientes):** en **Configuración → API
  privada**, pegá el `access_token` de una app creada en
  `https://developers.tiendanube.com` y así importar pedidos y clientes reales
  (`GET /v1/orders`, `GET /v1/customers`).

> Nota técnica CORS: los navegadores bloquean las llamadas directas a
> mitiendanube.com. El modo **auto** encadena proxies públicos (allorigins,
> corsproxy.io, codetabs); el modo **directo** usa el servidor que aloje el
> prototipo (requiere CORS). Para producción definitiva se recomienda un
> backend con la API oficial o webhooks.

## Funciones

- Dashboard: ingresos, pedidos, ticket promedio, clientes, stock, top productos,
  canales, gráficos y registro de sincronización.
- Productos: catálogo sincronizado en vivo, filtro por stock bajo, precio
  override interno, estados y notas.
- Pedidos: alta, cambio de estado, canal, importación desde la API privada.
- Clientes: segmentación automática (VIP / Frecuente / Activo / Nuevo), tags,
  notas, alta de leads.
- Configuración: conector, token API, exportación CSV/JSON, importación de
  respaldo, gestión de la cuenta admin.

Los datos viven en `localStorage` del navegador (prototipo sin servidor) y son
exportables/restaurables en JSON.

## Conectar la tienda con la CRM (menú público)

La tienda es un SaaS (Tienda Nube), de modo que el "cambio" publicable es
administrativo: agregá en **Admin de la tienda → Diseño → Menú** un enlace
externo **"CRM"** apuntando a la URL publicada del prototipo (ver
`snippet-crm-tienda.txt`).

## Repositorio Git

El repositorio local ya fue inicializado y comiteado. Para publicarlo online:

1. Creá un repo vacío en GitHub (`gh repo create area-de-picnic-crm --private`
   o desde github.com → New repository).
2. Vinculalo y subí:
   ```bash
   git remote add origin https://github.com/TU-USUARIO/area-de-picnic-crm.git
   git push -u origin main
   ```
3. Activá **Settings → Pages** para servir la CRM desde `main`.

---

*Prototipo v1 — generado a partir del catálogo público real de
tiendadeareadepicnic.mitiendanube.com (11 productos).*

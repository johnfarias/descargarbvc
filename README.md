# descargarbvc
Descargar Informacion de la Bolsa de Valores de Colombia
----
Con una sencilla función es posible descagar información que provee la Bolsa de Valores en la página web www.bvc.com.co. Actualmente sólo está disponible la información de Acciones. Posteriormente se irán agregando más funciones para la informacion de Futuros y Renta Fija.

Para descargar esta librería en R, utiliza el comando:
`devtools::install_github("johnfarias/descargarbvc")`

Para cargar la librería en la sesión, utiliza el comando:
`library(descargarbvc)`

## Cómo usar el paquete 

En primer lugar, establezca un directorio de trabajo mediante el comando `setwd()`. En esta ruta, al utilizar la función principal `descargarAccion`, se creará una carpeta llamada 'Datos' que contendrá la información descargada de la bolsa.

El comando `descargarAccion()` se usa para obtener información de una Acción especifica que se negocia en bolsa. Se puede usar como argumento, un vector de cadenas de texto con los nemotécnicos. Por ejemplo, para obtener varios activos a la vez usamos `descargarAccion(c("TERPEL","EEB","ECOPETROL"))`. O simplemente una cadena de texto con el nemotécnico del activo `descargarAccion("ETB")`. En cualquiera de los dos casos, se creará una variable tipo `xts` (Serie de tiempo con fechas) por cada activo puesto como argumento. 

Por defecto se descarga un periodo de 182 dias contando desde el dia de consulta hacia atrás. Y es que la bolsa solo permite descargas de 182 dias en formato `.xls`. Sin embargo se puede establecer un rango de fechas más amplio dentro de la función. R descargará periodos de a 182 dias en formato Excel, luego los unificará en un archivo `.csv` y finalmente los dejará almacenados en memoria, listos para procesar graficos o análisis estadísticos. El archivo `.csv` es el único que permanecerá dentro de la carpeta 'Datos' y los archivos de excel serán eliminados. Especifique el rango de fechas que desea descargar, por ejemplo `descargarAccion("EEB",fecha.ini="2015-01-01",fecha.fin="2017-01-01")`. Esto será todo lo necesario para comenzar a usar este paquete.

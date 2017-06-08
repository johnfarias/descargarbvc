# TODO: Descaga informacion de acciones de la bolsa de valores de colombia.
# 
# Author: JOHN FREDY ARIAS GIRALDO
###############################################################################
require(XLConnect)
require(xts)
require(zoo)
#################################################################################
## DESCARGAR ACCIONES
#################################################################################
#' @title Descargar Accion
#' 
#' @description Descarga una o varias acciones para un rango de fechas especificado. 
#' @param nemo Una cadena de texto o vector de cadenas de texto con el nemotecnico de la accion a descargar.
#' @param fecha.ini Una fecha inicial para comenzar la descarga.
#' @param fecha.fin Una fecha final para la descarga.
#' @param nombre.archivo Establece un nombre para el archivo descargado. Por defecto, es el nemotecnico.
#' @note Por defecto, si no se ingresan fechas para fecha.ini y fecha.fin, descarga los precios de los ultimos 182 dias.
#' @author John Fredy Arias
#' @usage descargarAccion(nemo, fecha.ini = Sys.Date()-182, fecha.fin = Sys.Date(), nombre.archivo = nemo)
#' @return Devuelve un objeto xts con los datos de la accion descargada.
#' @export descargarAccion
#' @examples 
#' descargarAccion("TERPEL")
#' descargarAccion(c("TERPEL","EEB")))
#' descargarAccion("TERPEL",fecha.ini="2015-12-31",fecha.fin="2016-12-31")
descargarAccion = function(nemo, fecha.ini = Sys.Date()-182, fecha.fin = Sys.Date(), nombre.archivo = nemo, dec=",", sep=";"){
	
	## requiere el paquete XLConnect
	require(XLConnect)
	
	## establece la ruta de descarga en el directorio de trabajo
	ruta = getwd()
	
	## comprueba que el nemo sea cadena de texto
	if(class(nemo)!="character") stop("el argumento 'nemo' no es una cadena de texo o un vector de cadenas de texto.")
	
	## comprueba que la fecha fin no sea menor a la fecha inicio
	if(missing(fecha.ini)==FALSE | missing(fecha.fin)==FALSE) {
		fecha.fin = as.Date(fecha.fin)
		fecha.ini = as.Date(fecha.ini)
		if(as.Date(fecha.fin)<as.Date(fecha.ini)) stop("La fecha.fin debe ser mayor que la fecha.ini.")
	}	
	
	## cuenta los dias entre las dos fechas
	dias = as.numeric(fecha.fin - fecha.ini)
	
	## indica cuantos semestres deben descargarse
	assign("semestres", ceiling(dias/182),envir=.GlobalEnv)
	
	ff = fecha.fin
	fi = ff-180
	if(fi<fecha.ini) fi=fecha.ini
	
	## si no existe, crea una carpeta llamada 'Datos' 
	shell(paste0("if not exist ",ruta,"/Datos ","Md ",ruta,"/Datos"),intern=TRUE,translate=TRUE)
	
	## para cada semestre de descarga
	for(s in 1:semestres){
		
		## especifica la url y el directorio de descarga
		url = paste0("http://www.bvc.com.co/mercados/DescargaXlsServlet?archivo=acciones_detalle&nemo=",nemo,"&tipoMercado=1&fechaIni=",fi,"&fechaFin=",ff)
		dir = paste0(ruta, "/Datos/", nombre.archivo)
		
		## procede descargar cada url
		for(i in 1:length(url)){
			try(download.file(url[i],paste0(dir[i],"_",s,".xls"),mode="wb",method="wget"))
		}
		
		#calcula el siguiente intervalo de fechas
		ff=fi-1
		fi=fi-183
		if(fi<fecha.ini) fi=fecha.ini
		
	}
	
	## devuelve la variable nemos con la lista de las acciones descargadas
	assign("nemos",nemo,envir=.GlobalEnv)
	
	## Procesa la informacion de tamanho de archivos
	procesarInformacion()
	
	## Procesa todos los archivos de excel y los convierte en un solo archivo csv
	procesarArchivosXLS(sep=sep,dec=dec)
	
	## Elimina los archivos de excel innecesarios
	eliminarArchivosXLS()
	
	## Eliminar variables innecesarias
	rm(DataByt,nemos,semestres,envir=.GlobalEnv)
	
	## Devuelve el nombre de las acciones descargadas
	return(nemo)
		
}
#descargarAccion(c("PFBCOLOM","TERPEL","EEB"),fecha.ini="2016-10-01")

#################################################################################
## LEER INFORAMCION DEL TAMANHO DE LOS ARCHIVOS DESCARGADOS
#################################################################################
#' @title procesarInformacion
#' 
#' @description Consulta el tamanho de los archivos descargados.
#' @param ruta Establece una ruta para buscar la informacion de los archivos.
#' @author John Fredy Arias
#' @examples 
#' procesarInformacion()
#' @export procesarInformacion
procesarInformacion = function(ruta=paste0(getwd(),"/Datos")){
	
	## Limpia la variable DataByt en caso de haberse creado anteriormente
	assign("DataByt",NULL,envir=.GlobalEnv)
	
	## devuelve una cadena con la informacion del nombre de los archivos y el peso
	## dependiendo de la version del sistema operativo windows, puede cambiar el formato
	cadena = paste0('cd ',ruta,'/ & dir')
	infoBytes = shell(cadena,intern=TRUE,translate=TRUE)
	lib = length(infoBytes)
	infoBytes = infoBytes[c(8:(lib-2))]
	infoBytes = strsplit(infoBytes," ")
	
	DataBytes = c()
	DataNames = c()
	for(el in 1:length(infoBytes)){
		nel = length(infoBytes[[el]])
		nborra = c()
		for(sel in 1:nel){
			if(infoBytes[[el]][sel]=="") nborra=c(nborra,sel)
		} 
		infoBytes[[el]] = infoBytes[[el]][-nborra]
		DataBytes[el] = infoBytes[[el]][3] ## depende del sistema operativo hay que cambiar esta columna
		DataNames[el] = infoBytes[[el]][4] ## depende del sistema operativo hay que cambiar esta columna
	}
	DataBytes = as.numeric(DataBytes)
	DataNames = as.character(DataNames)
	assign("DataByt" ,as.data.frame(list("Names"=DataNames,"Bytes"=DataBytes)),envir = .GlobalEnv)
	return(list("DataByt"=DataByt,"semestres"=semestres))
}
#procesarInformacion()

#################################################################################
## PROCESAR ARCHIVOS PARA CREAR UN ARCHIVO COMPILADO CSV PARA CADA ACCION 
#################################################################################
#' @title procesarArchivosXLS
#' 
#' @description Procesa todos los archivos de excel descargados de la pagina de la BVC, y compila toda
#' la informacion en un unico archivo csv.
#' @param ruta Establece  la ruta para procesar los archivos de excel descargados de la BVC.
#' @param dec Establece el simbolo con el cual se deben separar los decimales en el archivo csv que se va a crear.
#' @param sep Establece el simbolo con el cual se deben separar las celdas en el archivo csv que se va a crear.
#' @author John Fredy Arias
#' @examples 
#' procesarArchivosXLS()
#' @export procesarArchivosXLS
procesarArchivosXLS = function(ruta=paste0(getwd(),"/Datos"),dec,sep){

	## Numero de nemotecnicos descargados
	nlista = length(nemos)
	
	for(j in 1:nlista){
		## Iniciar el dataframe para almacenar todos los archivos descargados 
		DataCsv=NULL
		
		## Recorre todos los archivos descargados para una sola accion
		for(l in semestres:1){
			
			## Si el archivo tiene datos, pesa diferente de cero
			if(DataByt[which(DataByt[,1] == paste0(nemos[j],"_",l,".xls")),2] != 0){
				
				## abre el archivo de excel
				lis = loadWorkbook(paste0(ruta,"/",nemos[j],"_",l,".xls"))
				
				## abre la hoja llamada 'Resultado'
				df = readWorksheet(lis,"Resultado")
				
				## almacenamos los datos en un unico data frame
				DataCsv = rbind(DataCsv,df)
				
				## creamos una nueva variable con el nemo tecnico
				assign(nemos[j],as.xts(read.zoo(DataCsv[,-c(1)])),envir=.GlobalEnv)
				
				## limpiamos las variables
				lis = NULL
				df = NULL
			} else(next)
		}
		
		## Exportar csv compilando informacion de acciones
		write.table(DataCsv,file=paste0(ruta,"/",nemos[j],".csv"),sep=sep,dec=dec,row.names=FALSE)#,row.names=as.character(index(DataCsv)))
		
		## Elimiamos el dataframe
		DataCsv = NULL
	}
}
#procesarArchivosXLS()

################################################################################
# ELIMINAR LOS ARCHIVOS DE EXCEL DESCARGADOS
################################################################################
#' @title eliminarArchivosXLS
#' 
#' @description Una vez que se haya compilado la informacion en el archivo csv mediante
#' la funcion procesarArchivosXLS, se eliminan los arhivos de excel descargados de la BVC.
#' @param ruta Establece la ruta donde se encuentran los archivos de excel a descargar.
#' @author John Fredy Arias
#' @examples 
#' eliminarArchivosXLS()
#' @export eliminarArchivosXLS
eliminarArchivosXLS = function(ruta = paste0(getwd(),"/Datos")){
	shell(paste0("cd ",ruta," & del *.xls"),intern=TRUE,translate=TRUE)
}
#eliminarArchivosXLS()


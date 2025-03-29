/*
  Configuración de los properties estandar para los mensajes, etiquetas, o botones
     
  Para el manejo de las tildes o Ñ's se deben usar los siguientes códigos.
  á 	= \u00E1		é 	= \u00E9		í 	= \u00ED		ó 	= \u00F3		ú 	= \u00FA
  Á 	= \u00C1		É 	= \u00C9		Í 	= \u00CD		Ó 	= \u00D3		Ú 	= \u00DA    
  ñ 	= \u00F1		Ñ 	= \u00D1
  -  	= \u002D   		·	= \u00B7	
 */
// precarga de imágenes 
/**
 * Despliega y repliega un div con su respectivo cambio para las imagenes...
 */

function desplegar ( Div , idImg , imgI , imgF , ext , Div2) {		
	try {	
		var img	= document.getElementById( idImg ) ;
		if ( document.getElementById( Div ).style.display == 'block' ){
			document.getElementById( Div ).style.display = 'none' ;
			document.getElementById( Div2 ).style.marginLeft = '2%' ;
			img.src = 'images/'+ imgF +'.'+ ext +'' ;							
		} else if ( document.getElementById( Div ).style.display == 'none' ) {
			document.getElementById( Div ).style.display = 'block' ;
			document.getElementById( Div2 ).style.marginLeft = '26%' ;
			img.src= 'images/'+ imgI +'.'+ ext ;						
		}
	} catch ( e ) {
		alert  ( e.message ) ;
	}
}
/*
  Configuraci�n de los properties estandar para los mensajes, etiquetas, o botones
     
  Para el manejo de las tildes o �'s se deben usar los siguientes c�digos.
  � 	= \u00E1		� 	= \u00E9		� 	= \u00ED		� 	= \u00F3		� 	= \u00FA
  � 	= \u00C1		� 	= \u00C9		� 	= \u00CD		� 	= \u00D3		� 	= \u00DA    
  � 	= \u00F1		� 	= \u00D1
  -  	= \u002D   		�	= \u00B7	
 */
// precarga de im�genes 
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
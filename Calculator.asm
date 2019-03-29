;*********************PROGRAMA EXTRAIDO DEL LIBRO "ENSAMBLADOR BASICO"******************** 
;   Descripcion del programa:
;       Todos los temas vistos en la unidad II se tendran que cubrir en este programa
;       por lo que el objetivo es utilizar en este programa todas las etiquetas de la
;       unidad II asi que el porgrama consta sobre la utilizacion de las etiquetas.                 

;   Comienzo del programa
.model small
.data                    

;   Definiendo variables y mensajes a utilizar en nuestro programa

    ErrorCAP db 0           ;Bandera de error en la captura de las cantidades
    Cantidad db 0           ;La cantidad sobre la que se opera, Si es 0 se
                            ;opera sobre la cantidad 1, si es 1 se opera sobre
                            ;la cantidad 2.
    CantUnoR dw 0           ;variable que guarda la cantidad 1 convertida en binario
    CantDosR dw 0           ;variable que guarda la cantidad 2 convertida en binario
    CantUnoN db 6,0,6 DUP(?);variable que almacena la cantidad 1
    CantDosN db 6,0,6 DUP(?);variable que almacena la cantidad 2
    Funcion  db 0           ;variable que guarda la funcion a realizar
    Resulta  db 13,10,13,10,'El resultado es: $'
    ResultaR db 11 DUP(?)
    Mensaje  db 'Bienvenidos al programa que le permite realizar las'
             db 13,10
             db 'operaciones basicas de Multiplicacion, Division, Suma'
             db 13,10,'y Resta sobre dos cantidades enteras.'
             db 13,10,13,10,'$'
    Pregunta db 13,10,13,10,'Digite:',13,10,13,10
             db ' (1) para Multiplicar.',13,10
             db ' (2) para Dividir',13,10                
             db ' (3) para Sumar.',13,10
             db ' (4) para Restar.',13,10
             db ' (5) para Terminar.',13,10,'$'
    Error    db 7,7,7,13,10,'ERROR : En la seccion de las opciones.'
             db 13,10,13,10,'$'
    Error1   db 7,7,7,13,10,'ERROR : digito INVALIDO en CANTIDAD 1.'
             db 13,10,13,10,'$'
    Error2   db 7,7,7,13,10,'ERROR : digito INVALIDO en CANTIDAD 2.'
             db 13,10,13,10,'$'                         
    Error3   db 7,7,7,13,10,'ERROR : Cantidad fuera de RANGO (65535)'
             db '!!!'
             db 13,10,13,10,'$'
    Error4   db 7,7,7,13,10,'ERROR : intento de DIVISION por CERO.'
             db 13,10,13,10,'$'                                    
    CantunoM db 13,10,13,10,'Digite primer CANTIDAD (debe ser < 65535)'
             db ' : $'
    CantdosM db 13,10,13,10,'Digite segunda CANTIDAD (debe ser < 65535)'
             db ' : $'
    
    ;-------------------------------------------------------------------
    ;TABLA DE POTENCIAS USADA PARA CONVERTIR EL RESULTADO BINARIO DE LA
    ;OPERACION EN FORMATO ASCII, SE USAN LAS POTENCIAS DE 10 (1, 10, 100, 1000
    ; Y 10000), PORQUE EL NUIMERO MAS GRANDE ES 65535. EN CASO DE QUE QUIERA 
    ;OPERAR SOBRE NUMEROS MAS GRANDES AMPLIE LA TABLA.
    ;-------------------------------------------------------------------
    
    Potencia dw 0001h, 000Ah, 0064h, 03E8h, 2710h
    PotenciaF dw $
          
.code
    
    Empieza:
        
    ;-------------------------------------------------------------------
    ;BORRA LA PANTALLA CAMBIANDO LA MODALIDAD DE VIDEO. ESTA FORMA DE BORRAR
    ;LA PANTALLA ES MUY PECULIAR Y SE CONSIDERA UN "TRUCO". SE BASA EN EL
    ;HECHO DE QUE AL CAMBIAR LA MODALIDAD DE VIDEO, EL PROPIO BIOS (HARDWARE)
    ;BORRA LA PANTALLA POR NOSOTROS. ES UN METODO BURDO PERO MUY EFICIENTE.
    ;--------------------------------------------------------------------
    
        mov Ah, 0Fh             ;obtiene la modalidad de video actual
        int 10h
        mov Ah, 0               ;cambia la modailidad de video que se obtuvo
        int 10h
        mov Ax, @Data           ;inicializa DS con la direccion @Data
        mov Ds, Ax
        mov Dx, Offset Mensaje  ;despliega el mensaje de bienvenida
        call Imprime
        mov Si, Offset ResultaR ;Inicializa la variable ResultaR
        add Si, 11
        mov Al, '$'
        mov [Si], Al
    
    ;---------------------------------------------------------------------
    ;SE DESPLIEGA EL MENU DE OPCIONES A ELEGIR. LA OPCION DE ELEGIDA DEBE ESTAR
    ;COMPRENDIDA ENTRE 1 Y 5. ESTO ES VERIFICADO POR LAS INSTRUCCIONES CMP,
    ;JAE (SALTA SI ES MAYOR O IGUAL A) Y JBE (SALTA SI ES MENOR O IGUAL A).
    ;NOTE QUE LA SELECCION "NO ES DESPLEGADA EN LA PANTALLA", ESO SE DEJA A SU
    ;CREATIVIDAD. SI EXISTE ALGUN ERROR, SE DESPLEGARA EL MENSAJA APROPIADO.
    ;---------------------------------------------------------------------
    
    
    OTRA:
        
        mov Dx, Offset Pregunta ;Despliega el menu de opciones
        call Imprime
        call ObtenTecla
        cmp Al, 49              ;la seleccion del usuario es mayor o igual a 1
        jae SIGUE
        
        mov Dx, Offset Error    ;No despliega el mensaje de error
        call Imprime
        jmp OTRA
    
    SIGUE:
    
        cmp Al, 53              ;¨La seleccion del usuario es menor o igual 
        jbe TODOBIEN            ; a 5?
        mov Dx, Offset Error    ;No despliega el mensaje de error
        mov Ah, 09
        int 21h
        jmp OTRA
    
    TODOBIEN:
        
        cmp Al, 53
        jnz CHECATODO
        jmp FUNCION5
    
    CHECATODO:
        
        mov Funcion, Al         ;Guarda la funcion a realizar
        
    
    ;---------------------------------------------------------------------
    ;SE CAPTURAN LAS CANTIDADES Y SE GUARDAN EN SUS RESPECTIVAS VARIABLES PARA 
    ;PODER TRABAJAR SOBRE ELLAS MAS ADELANTE. LA CAPTURA SE BASA EN LA FUNCION
    ;09 DE LA INT 21H. DICHA FUNCION ESTABLECE QUE EL REGISTRO AH CONTENGA 09
    ;Y EL REGISTRO PARA DS:DX APUNTE A LA DIRECCION DE LA VARIABLE QUE ALMACENARA
    ;LA ESTRUCTURA DEL BUFFER, EL CUAL DEBE ESTAR CONSTRUIDO DE LA SIGUIENTE MANERA:
    ;
    ;   BYTE1 = CANTIDAD DE BYTES POR LEER
    ;   BYTE2 = (LLENADO POR MS-DOS) ES LA CANTIDAD DE BYTES REALMENTE LEIDOS.
    ;   BYTE3 = BUFFER DONDE SE ALMACENA EL RESULTADO; DEBE ENCONTRARSE 
    ;   INICIALIZANDO CON LA MISMA CANTIDAD DE BYTES ESPECIFICADOS POR EL BYTE1,
    ;
    ;LAS CANTIDADES CAPTURADAS REPRESENTAN UNA CADENA QUE ES NECESARIO CONVERTIR EN 
    ;BINARIO ANTES DE QUE SE PUEDA OPERAR SOBRE ELLA. MAS ADELANTE SERA EVIDENTE LO
    ;ANTERIOR.
    ;---------------------------------------------------------------------
    
    ;---------------------------------------
    ;   CAPTURA PRIMERA CANTIDAD
    ;---------------------------------------
    
    CAPCANT01:
        
        mov Dx, Offset CantunoM     ;mensaje de la captura de la cantidad 1
        call Imprime
        mov Ah, 0Ah                 ;captura la cantidad (hasta 8 digitos). 
        mov Dx, Offset CantUnoN
        int 21h
        mov ErrorCAP, 0             ;supone que no hay errores y que se esta
        mov Cantidad, 0             ;operando sobre la cantidad 1
        call ConvNUM
        cmp ErrorCAP, 1             ;¨Hubo Error?
        jz CAPCANT01                ;si, regresa a la captura
        mov CantUnoR, Bx            ;guarda el resultado de la conversion
        
    ;---------------------------------------
    ;   CAPTURA SEGUNDA CANTIDAD
    ;---------------------------------------
    
    CAPCANT02:
        ;POR AQUI ESTA EL ERROR WE YA LO SOLUCIONE 
        
        ;mov ErrorCAP, 0             ;Supone que no hay error              
        ;mov Cantidad, 1             ;Indica a ConvNUM que es la segunda cantidad
        mov Dx, Offset CantdosM     ;mensaje de la captura de la cantidad 2
        call Imprime
        mov Ah, 0Ah                 ;captura la cantidad (hasta 8 digitos). 
        mov Dx, Offset CantDosN
        int 21h
        mov ErrorCAP, 0             ;Supone que no hay error              
        mov Cantidad, 1             ;Indica a ConvNUM que es la segunda cantidad
        call ConvNUM
        cmp ErrorCAP, 1             ;¨Hubo Error?
        jz CAPCANT02                ;si, regresa a la captura
        mov CantDosR, Bx            ;guarda el resultado de la conversion
    
    ;-------------------------------------------------------------------
    ;DESPUES DE CAPTURAR LAS DOS CANTIDADES SOBRE LAS CUALES SE VA A OPERAR, 
    ;SE DEFINE CUAL ES LA FUNCION POR REALIZAR (MULTIPLICACION, DIVISIONM 
    ;SUMA O RESTA ).
    ;-------------------------------------------------------------------
    
        mov Al, Funcion             ;funcion que seleccion el usuario
        cmp Al, 31h                 ;¨es 1?
        jne FUNCION2                ;no
        call Multiplica             ;multiplica las dos cantidades
        jmp OTRA
    
    FUNCION2:
        
        cmp Al, 32h                 ;¨es 2?
        jne FUNCION3                ;No
        call Divide                 ;divide las dos cantidades
        jmp OTRA
        
    
    FUNCION3:
        
        cmp Al, 33h                 ;¨es 3?
        jne FUNCION4                ;No
        call Suma                   ;suma las dos cantidades
        jmp OTRA
    
    
    FUNCION4:
        
        cmp Al, 34h                 ;¨es 4?
        jne FUNCION5                ;No
        call Resta                  ;resta las dos cantidades
        jmp OTRA
    
    
    FUNCION5:
        
        mov Ax, 4C00h               ;Termina el programa
        int 21h
        
    
    ;-----------------------------------------
    ;           FIN DEL PROGRAMA
    ;-----------------------------------------
    
    
    ;********************************************************
    ;                   RUTINAS DE SOPORTE                   
    ;********************************************************
    
    ;--------------------------------------------------------
    ;Rutina     : Multiplica
    ;Proposito  : Multiplica dos numeros enteros sin signo
    ;Parametros : En el registro Ax el multiplicando y en Bx el multiplicador
    ;Regresa    : El resultado en el registro par Dx:Ax, que esta desplegado en
    ;             la pantalla
    ;--------------------------------------------------------
    
    Multiplica Proc Near
        
        xor Dx, Dx                  ;Dx es igual a 0 por si acaso
        mov Ax, CantUnoR            ;Primera cantidad (multiplicando)
        mov Bx, CantDosR            ;Segunda cantidad (multiplicando)
        mul Bx                      ;Multiplica
        call ConvASCII              ;Convierte en Ascii
        mov Dx, Offset Resulta      ;Prepara para desplegar la cadena
        call Imprime                ;resultado
        mov Dx, Offset ResultaR     ;Despliega el resultado
        call Imprime
        ret
    
    Multiplica Endp
    
    ;--------------------------------------------------------
    ;Rutina     : Divide
    ;Proposito  : Divide dos numeros enteros sin signo
    ;PArametros : En el registro Ax el dividendo y en Bx el divisior
    ;Regresa    : El resultado en el registro pas Dx:Ax, que es despelgado en 
    ;             la pantalla.
    ;--------------------------------------------------------
    
    Divide proc Near
        
        mov Ax, CantUnoR            ;carga la cantidad 1 (dividendo).
        mov Bx, CantDosR            ;carga la cantidad 2 (divisor).
        cmp Bx, 0                   ;error de division entre cero.
        
        jnz DIVIDE01
        mov Cantidad,3              ;Hubo error, asi qeu despliega el mensaje
                                    ; y salta.
        call HuboERROR
        ret
        
        DIVIDE01:
            
            div Bx                  ;Divide
            xor Dx, Dx              ;Dx=0. No se usa el residuo para simplificar
                                    ;las operaciones
            
            call ConvASCII          ;Convertir en ASCII
            mov Dx, Offset Resulta  ;Despliega la cadena del resultado
            call Imprime
            mov Dx, Offset ResultaR ;Despliega el resultado
            call Imprime
            ret
            
    Divide Endp
    
    ;------------------------------------------------------------
    ;Rutina     : Suma
    ;Proposito  : Suma dos numeros enteros sin signo
    ;Parametros : En el registro Ax el primer numero y en Bx el segundo
    ;Regresa    : El resultado en el registro par Dx:Ax, que es desplegado
    ;             en la pantalla.
    ;------------------------------------------------------------
    
    Suma Proc Near
        
        xor Dx, Dx                  ;Dx=0 por si existe acarreo
        mov Ax, CantUnoR            ;Primera cantidad
        mov Bx, CantDosR            ;Segunda cantidad
        add Ax, Bx                  ;la suma
        jnc SUMACONV                ;¨Hubo acarreo?
        add Dx, 0                   ;si
        
        SUMACONV:
        
            call ConvASCII              ;Convierte el resultado en ASCII
            mov Dx, Offset Resulta      ;Despliega la cadena de resultado
            call Imprime                
            mov Dx, Offset ResultaR     ;Despliega el resultado
            call Imprime
            ret
    
    Suma Endp
    
    ;------------------------------------------------------------
    ;Rutina     : Resta
    ;Proposito  : Resta dos numeros enteros sin signo
    ;Parametros : En el registro Ax el primer numero y en Bx el segundo
    ;Regresa    : El resultado en el registro par Dx:Ax, que es desplegado
    ;             en la pantalla.
    ;------------------------------------------------------------
    
    Resta Proc Near
        
        xor Dx, Dx                  ;Dx=0 por si existe acarreo
        mov Ax, CantUnoR            ;Primera cantidad
        mov Bx, CantDosR            ;Segunda cantidad
        sub Ax, Bx                  ;la resta
        jnc RESTACONV               ;¨Hubo acarreo?
        sbb Dx, 0
        
        RESTACONV:
            call ConvASCII          ;Covierte ASCII
            mov Dx, Offset Resulta  ;Despliega Cadena de Resultado
            call Imprime
            mov Dx, Offset ResultaR ;Despliega el resultado
            call Imprime
            ret
    Resta Endp
    
    ;------------------------------------------------------------
    ;Rutina     : Imprimir
    ;Proposito  : Despliega una cadena
    ;Parametros : En el registro Dx contiene el desplazamiento de la cadena
    ;Regresa    : Nada
    ;------------------------------------------------------------
    
    Imprime Proc Near
        
        mov Ah, 09                  ;Prepara para desplegar la cadena a traves de
        int 21h                     ;Int 21h
        ret
        
    Imprime Endp
    
    ;------------------------------------------------------------
    ;Rutina     : ObtenTecla 
    ;Proposito  : Espera a que el usuario digite una tecla 
    ;Parametros : Ninguno
    ;Regresa    : Regresa en el registro Al el codigo ASCII de la tecla                          
    ;------------------------------------------------------------      
    
    ObtenTecla Proc Near
        
        mov Ah, 0                   ;Lee una tecla desde el teclado a traves de Int 16h
        int 16h
        ret
        
    ObtenTecla Endp
    
    ;------------------------------------------------------------
    ;Rutina     : ConvNUM
    ;Proposito  : Convertir una cadena en un entero largo 
    ;Parametros : La longitud de la cadena y la direccion de la misma, y se 
    ;             pasan a la pila  
    ;Regresa    : En el registro Bx la cadena convertida en numero
    ;------------------------------------------------------------ 
    
    ConvNUM Proc Near
        
        mov Dx, 0Ah                 ;Multiplicador es 10
        cmp Cantidad, 0              ;¨Es la cantida 1?
        jnz CONVNUM01               ;No asi que la cantidad 2
        mov Di, Offset CantUnoN + 1 ;Bytes leido de a cantidad 1
        mov Cx, [Di]
        mov Si, Offset CantUnoN + 2 ;la cantidad 1
        jmp CONVNUM02
        
        CONVNUM01:
            ;*************ESTO ESTABA DANDO ERROR********************
            ;                   ARREGLADO
            
            mov Di, Offset CantDosN + 1 ;Bytes leidos de la cantidad 2
            mov Cx, [Di]
            mov Si, Offset CantDosN + 2 ;la cantidad 2
        
        CONVNUM02:
            
            xor Ch, Ch                  ;Ch=0
            mov Di, Offset Potencia     ;Direccion de la tabla de potencias
            dec Si                      ;Posiciona Si en el primer byte de la 
            add Si, Cx                  ;cadena capturada y le suma el
            xor Bx, Bx                  ;desplazamiento de bytes leidos,
            std                         ;para que podamos posicionarnos en el
                                        ;final de la misma (apunta al ultimo 
                                        ;digito capturado). Bx =0 y lee la
                                        ;cadena en forma inversa; es decir, de
                                        ;atras hacia adelante.
        CONVNUM03:
            
            lodsb                       ;levanta un byte del numero (esta instruccion indica
                                        ;que el registro Al sera cargado con el contenido 
                                        ;de la direccion apuntada por Ds:Si.
            cmp Al, "0"                 ;¨Es menor que 0 ? (Entonces no es un digito valido)
            jb CONVNUM04                ;Si, despliega el mensaje de error y termina
            cmp Al, "9"                 ;¨Es mayor que 9 ? (Entonces no es un digito valido)
            ja CONVNUM04                ;Si, despliega el error y salta 
            sub Al, 30h                 ;Convierte el digito ASCII a binario
            cbw                         ;Convierte a palabra
            mov Dx, [Di]                ;Obtiene la potencia de 10 que sera usada para 
            mul Dx                      ;multiplicar, multiplica el numero y lo suma
            jc CONVNUM05                ;a Bx, revisa si hubo acarreo, y si lo hubo, esto
            add Bx, Ax                  ;significa que la cantidad es > 65535.
            jc CONVNUM05                ;Si hay acarreo la cantidad es > 65535
            add Di, 2                   ;va a la siguiente potencia de 10 
            loop CONVNUM03              ;Itera hasta que Cx sea 0
            jmp CONVNUM06
            
        
        CONVNUM04:
            
            call HuboERROR              ;Algo ocurrio, despliega el mensaje y salta
            jmp CONVNUM06
        
        CONVNUM05:
            
            mov Cantidad, 2             ;Hubo acarreo en la conversion, por tanto la 
            call HuboERROR              ;cantidad capturada es mayor a 65535
        
        CONVNUM06:
            
            cld                         ;Regresa a la bandera de direccion           
            ret                         ;y regresa
            
    ConvNUM Endp
    
    ;------------------------------------------------
    ;Rutina     :   ConvASCII
    ;Proposito  :   Convertir un valor binario en ASCII
    ;Parametros :   El registro par Dx:Ax
    ;Regresa    :   Nada, pero almacena el resultado en el Buffer ResultaR
    ;------------------------------------------------
    
    ConvASCII Proc Near
        
    ;------------------------------------------------
    ;Lo primero que se hace es inicializar la variable que contendra el 
    ;resultado de la conversion.
    ;------------------------------------------------
    
        push Dx
        Push Ax                         ;Guarda el resultado
        mov Si, Offset ResultaR         ;Inicializa la variable ResultaR llenandola
        mov Cx, 10                      ;con asteriscos
        mov Al, '*'
        
        ConvASCII01:
            
            mov [Si], Al
            inc Si
            loop ConvASCII01
            pop Ax
            pop Dx
            mov Bx, Ax                  ;Palabra baja de la cantidad
            mov Ax, Dx                  ;Palabra alta de la cantidad
            mov Si, Offset ResultaR     ;Cadena donde se guardara el resultado
            add Si, 11
            mov Cx, 10                  ;Divisor igual a 10
        
        OBTENDIGITO:
            
            dec Si
            xor Dx, Dx                  ;Dx contendra el residuo
            div Cx                      ;Divide la palabra alta (Ax)
            mov Di, Ax                  ;Guarda el cociente (Ax)
            mov Ax, Bx                  ;Ax = palabra baja
            div Cx                      ;Dx tenia un residuo de la division anterior
            mov Bx, Ax                  ;Guarda el cociente
            mov Ax, Di                  ;Regresa la palabra alta
            add Dl, 30h                 ;Convierte el residuo en ASCII
            mov [Si], Dl                ;Lo almacena
            or Ax, Ax                   ;¨Palabra alta es 0?
            jnz OBTENDIGITO             ;No, sigue procesando
            or Bx, Bx                   ;¨Palabra baja es 0?
            jnz OBTENDIGITO             ;No, sigue procesando
            ret
    
    ConvASCII Endp
        
    ;-------------------------------------------------------
    ;Rutina     :   HuboERROR
    ;Proposito  :   Desplegar el mensaje de error adecuado
    ;Parametros :   Nada
    ;Regresa    :   Nada
    ;-------------------------------------------------------
    
    HuboERROR Proc Near
        
        cmp Cantidad, 0                 ;¨Es la cantidad 1?
        jnz HUBOERROR02                 ;No.
        mov Dx, Offset Error1
        call Imprime
        mov ErrorCAP, 1                 ;Enciende la bandera de error
        jmp HUBOERROR05
        
        HUBOERROR02:
            
            cmp Cantidad, 1             ;¨Es la cantidad 2?
            jnz HUBOERROR03             ;No
            mov Dx, Offset Error2
            call Imprime
            mov ErrorCAP, 1
            jmp HUBOERROR05
                    
        HUBOERROR03:
            
            cmp Cantidad, 3             ;¨Cantidad capturada esta fuera de rango?
            jnz HUBOERROR04             ;No
            mov Dx, Offset Error3
            call Imprime
            mov ErrorCAP, 1
            jmp HUBOERROR05
        
        HUBOERROR04:
            
            mov Dx, Offset Error2       ;Error de intento por division por cero
            call Imprime
            mov ErrorCAP, 1
        
        HUBOERROR05:
            
            ret
        
        HuboERROR Endp

.stack
End Empieza

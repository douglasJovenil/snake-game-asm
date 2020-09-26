.model small

.stack 100H                                    

.data
  head_i      equ 1                   ; Posicao inicial Y da cobra
  head_j      equ 1                   ; Posicao inicial X da cobra
  axis_to_inc db 'r'                  ; Armazena a direcao em que a cobra ira se movimentar
  score       dw 1                    ; Armazena os pontos do jogador

  food_i db ?                         ; Armazena a posicao Y da comida
  food_j db ?                         ; Armazena a posicao X da comida

  false equ 0                         ; Define de false
  true  equ 1                         ; Define de True

  ticks           dw 0                ; Para a implementacao do delay
  flag_delay      db 0                ; Flag para verificar quando o delay passou
  interval_delay  equ 60              ; delay em ms | min = 55
  
  snake_color       equ 0AH           ; Verde claro
  edge_color        equ 01H           ; Azul
  background_color  equ 00H           ; Preto
  food_color        equ 0CH           ; Vermelho claro  
  font_color        equ 0AH           ; Verde Claro
  
  snake_char  equ 254                 ; Caractere que representa a cobra    
  food_char   equ 3                   ; Caractere que representa a comida   

  edge_char           equ 177                                   ; Caractere que representa a moldura
  edges_i_init        equ 0                                     ; Posicao inicial Y das bordas
  edges_i_end         equ 24                                    ; Posicao final Y das bordas
  edges_j_init        equ 0                                     ; Posicao incial X das bordas
  edges_j_end         equ 39                                    ; Posicao inicial J das bordas
  edges_j_half        equ 19                                    ; Posicao igual a metade do X das bordas
  edges_j_half_score  equ 3                                     ; Metade do tamanho do espaco onde sera escrito o score
  edges_j_score       db edges_j_half - edges_j_half_score + 1  ; Variavel que sera iterada para escrever o score
  score_j_init        equ edges_j_half - 1                      ; Posicao X inicial do Score

  title_full db   '    _____ _   _____    __ __ ______   / ___// | / /   |  / //_// ____/   \__ \/  |/ / /| | / ,<  / __/     ___/ / /|  / ___ |/ /| |/ /___    /____/_/ |_/_/  |_/_/ |_/_____/   '
  title_cols_len equ 35               ; Representa uma linha do titulo  | Modificar ao trocar o titulo
  title_rows_len equ 5                ; Quantidade de linhas do titulo  | Modificar ao trocar o titulo
  title_i        equ 9                ; Linha inicial, o maximo eh 21   | BOM SENSO AO MODIFICAR
  title_j        equ 2                ; Coluna inicial, o maximo eh 5   | BOM SENSO AO MODIFICAR

  authors     db 'Douglas J.C. Santos' ; String dos autores
  authors_len equ $-authors             ; Tamanho da string
  authors_i   equ 20                    ; Linha em que os autores serao printados
  authors_j   equ 40 - authors_len - 1  ; Coluna que os autores serao printados
           
  game_over_full     db ' __          ___   __      ___ __ / _` /\ |\/||__   /  \\  /|__ |__)\__>/~~\|  ||___  \__/ \/ |___|  \'
  game_over_cols_len equ 34           ; Quantidade de colunas da escrita de game over
  game_over_rows_len equ 3            ; Quantidade de linhas da escrita de game over
  game_over_i        equ 9            ; Linha inicial onde a escrita game over deve ser desenhada
  game_over_j        equ 3            ; Coluna inicial onde a escrita game over deve ser desenhada

  up_key_hex      equ 48H               ; Hexadecimal da tecla cima     em ASCII
  down_key_hex    equ 50H               ; Hexadecimal da tecla baixo    em ASCII
  right_key_hex   equ 4DH               ; Hexadecimal da tecla direita  em ASCII
  left_key_hex    equ 4BH               ; Hexadecimal da tecla esquerda em ASCII
  enter_key_hex   equ 0DH               ; Hexadecimal da tecla enter    em ASCII
  target_keys     db up_key_hex, right_key_hex, down_key_hex, left_key_hex, enter_key_hex   ; Teclas que serao procuradas no metodo read_char
  target_keys_len equ $-target_keys     ; Quantidade de caracteres que serao buscados

  menu_full     db 'jogarsair [jogar][sair]'  ; String do menu completo | Foi adicionado um espaco em braco apos a palavra sair para ambas as opcoes terem o mesmo tamanho
  menu_cols_len equ 5                         ; Quantidade de colunas da string menu_full
  menu_rows     equ 2                         ; Quantidade de linhas da string menu_full
  menu_i        equ  10                       ; Posicao Y inicial de menu_full
  menu_j        equ 17                        ; Posicao inicial X de menu_full

  open_close_selected_char db '[] '     ; Caracteres que ficarao ao redor da string menu_full

  menu_selected_option_index    db 0    ; Armazena a opcao selecionada no menu
  menu_unselected_option_index  db 1    ; Armazena a opcao nao selecionada no menu

  title_page      equ 0                 ; Indice da pagina de titulo
  menu_page       equ 1                 ; Indice da pagina de menu
  game_page       equ 2                 ; Indice da pagina do jogo
  game_over_page  equ 3                 ; Indice da pagina de game over 
  current_page    db title_page         ; Armazena o indice da pagina atual

  mapping_i_init  equ 0                 ; Posicao inicial da borda superior do mapa
  mapping_i_end   equ 24                ; Posicao final da borda inferior
  mapping_j_init  equ 0                 ; Posicao inicial da borda da esquerda
  mapping_j_end   equ 39                ; Posicao final da borda da direita

  snake_len equ 874                     ; Tamanho maximo que a snake pode atingir
  snake_mapping dw snake_len dup(0)     ; Posicoes em que a snake se encontra
  
.code

  ; ##################################### GERAL #####################################

  ; Salva o contexto e reseta os registradores
  push_all macro
    push AX 
    push BX 
    push CX 
    push DX

    push SI
    push DI
    push BP
  endm

  ; Retorna para o contexto salvo
  pop_all macro
    pop BP
    pop DI
    pop SI

    pop DX
    pop CX
    pop BX
    pop AX
  endm

  ; #################################### SISTEMA ###################################
  
  ; Inicializa os segmentos
  init_segments proc
    mov AX, @data
    mov DS, AX 
    mov ES, AX    ; Para poder escrever as string com a INT 10H
    ret
  endp

  ; Finaliza o programa
  finish_program proc
    mov AH, 4CH     ; 4C: exit Program. Servicos devem ser passado para AH antes da INT
    int 21H         ; Chama interupcao
    ret             ; Desempilha IP
  endp

  ; ##################################### VIDEO #####################################

  ; Inicializa o video no modo texto  
  setup_video proc
    push_all            ; Salva contexto
    mov AX, 0001H       ; AH = 00H ->Seta o modo de video | AL = 01H -> Configura modo de video texto 40 x 25  com 16 cores
    int 10H             ; Chama interrupcao de video

    ; Desabilita o cursor
    mov AH, 01H
    mov CX, 2607H
    int 10H

    pop_all             ; Retorna contexto
    ret                 ; Desempilha IP
  endp

  ; Seta a current_page para aparecer na tela
  set_page macro
    push_all
    mov AH, 05H
    mov AL, current_page
    int 10H
    pop_all
  endm

  ; #################################### STRING ###################################

  ; Escreve uma string na tela com 
  ; BP = Recebe o offset da string 
  ; CX = Recebe o tamanho da string
  ; DH = Recebe a linha inicial
  ; DL = recebe a coluna inicial 
  write_string macro
    push_all                            ; Salva contexto
    mov AX, 1301H                       ; AH = 13 -> Para poder escrever a string | AL = 01 -> string cont?m caracteres e atributos 
    mov BH, current_page
    int 10H                             ; Interrupcao
    pop_all                             ; Retorna contexto
  endm

  ; Escreve uma diversas linhas a partir de um DB
  ; NAO SALVA E NEM RETORNA O CONTEXTO
  ; BP -> Recebe a string com offset
  ; CX -> Recebe a quantidade de coluna de cada linha
  ; DH -> Linha inicial
  ; DL -> Coluna final
  ; AL -> Recebe a quantidade de linhas + a linha inicial
  write_full proc
    loop_write_full:
      mov BL, font_color
      write_string                      ; Escreve o valor de BP na tela
      add BP, CX                        ; Incrementa a linha do titulo
      inc DH                            ; Incrementa o contador de linhas
      cmp DH, AL                        ; Compara o contador de linhas com o maximo de linhas + linha inicial definida
      jne loop_write_full               ; Se o comparador de linhas for diferente do definido volta para o loop
    ret
  endp

  ; Escreve a title_full na tela
  write_title proc
    push_all                            ; Salva contexto
    mov CX, title_cols_len              ; Quantidade de caracteres para imprimir 
    mov DH, title_i                     ; Linha inicial
    mov DL, title_j                     ; Coluna inicial
    mov BP, offset title_full           ; Move o endereco base do titulo para BP
    mov AL, title_rows_len + title_i
    call write_full
    pop_all                             ; Retorna contexto
    ret
  endp

  ; Escreve os autores na tela
  write_authors macro
    push_all                ; Salva contexto
    mov BP, offset authors  ; String a ser escrita
    mov CX, authors_len     ; Quantidade de caracteres a serem impressos
    mov DH, authors_i       ; Linha
    mov DL, authors_j       ; Coluna
    mov BL, font_color
    write_string            ; Escreve a string
    pop_all                 ; Retorna contexto
  endm

  ; Escreve o menu na tela
  write_menu proc
    push_all                            ; Salva contexto
    mov CX, menu_cols_len               ; Quantidade de caracteres para imprimir 
    mov DH, menu_i                      ; Linha inicial
    mov DL, menu_j                      ; Coluna inicial
    mov BP, offset menu_full            ; Move o endereco base do titulo para BP
    mov AL, menu_rows + menu_i
    call write_full
    pop_all            
    ret
  endp

  ; Escreve os colchetes ao redor da opcao selecionada no menu
  write_brackets_menu proc
    push_all                                      ; Salva contexto
    mov CX, 1                                     ; Quantidade de caracteres a serem impressos
    mov DH, menu_i                                ; Posicao da linha
    add DH, menu_selected_option_index          ; Incremento da opcao selecionada
    mov BL, font_color
    
    mov BP, offset open_close_selected_char       ; Caractere '['
    mov DL, menu_j - 1                            ; Coluna
    write_string                                  ; Escreve a string

    mov BP, offset open_close_selected_char + 1   ; Caractere ']'
    mov DL, menu_j + menu_cols_len                ; Coluna
    write_string   

    mov BP, offset open_close_selected_char + 2   ; Caractere ' '
    mov DH, menu_i
    add DH, menu_unselected_option_index

    mov DL, menu_j + menu_cols_len                ; Coluna
    write_string                                  ; Escreve a string

    mov DL, menu_j - 1                            ; Coluna
    write_string                                  ; Escreve a string

    pop_all                                       ; Retorna contexto
    ret
  endp

  ; Escreve a tela de game over
  write_game_over proc
    push_all
    mov CX, game_over_cols_len              ; Quantidade de caracteres para imprimir 
    mov DH, game_over_i                     ; Linha inicial
    mov DL, game_over_j                     ; Coluna inicial
    mov BP, offset game_over_full           ; Move o endereco base do titulo para BP
    mov AL, game_over_rows_len + game_over_i
    call write_full
    pop_all
    ret
  endp


  ; AH = 09
  ; AL = ASCII character to write
  ; BH = display page  (or mode 13h, background pixel value)
  ; BL = character attribute (text) foreground color (graphics)
  ; CX = count of characters to write (CX >= 1)

  ; AH=02h Seta a posi??o do cursor
  ; DH = linha
  ; DL = coluna
  ; BH = n?mero da p?gina (default 0)

  ; Desenha UMA moldura
  ; DH = Linha
  ; DL = Coluna
  ; AL = Caractere
  write_char proc
    push_all

    mov BH, current_page

    mov AH, 02H      ; Atualiza a posicao
    int 10H

    mov AH, 09H      ; Escreve o caractere
    mov CX, 1        ; Recebe a quantidade de coluna de cada linha
    int 10H
    
    pop_all
    ret
  endp

  ; Escreve a moldura na tela
  write_edges proc
    push_all
    mov BL, edge_color
    mov AL, edge_char

    mov DH, edges_i_init        ; Linha inicial                   
    ; Desenha as colunas
    loop_col_write_edges:
      mov DL, edges_j_init      ; Escreve na coluna da esquerda
      call write_char

      mov DL, edges_j_end       ; Escreve na coluna da direita
      call write_char

      inc DH
      cmp DH, edges_i_end       ; Escreve ate a penultima linha
      jle loop_col_write_edges

      mov DL, edges_j_init      ; Coluna inicial
    ; Desenha as linhas
    loop_row_write_edges:
    
      mov DH, edges_i_end       ; Escreve a linha inferior
      call write_char

      cmp DL, edges_j_score     ; Verica se deve escrever o score, ou seja, espaco em braco
      je inc_edges_score_loop_row

      mov DH, edges_i_init      ; Escreve a linha superior
      call write_char

      jmp inc_row_loop_row

      ; Verifica se ja deixou todos os espacos em branco necessario para o score
      inc_edges_score_loop_row:
        cmp edges_j_score, edges_j_half + edges_j_half_score
        je inc_row_loop_row
        inc edges_j_score

      ; Incrementa a quantidade de espaco em branco escrito para o score
      inc_row_loop_row:
        inc DL
        cmp DL, edges_j_end
        jle loop_row_write_edges

    pop_all
    ret
  endp

  ; Escreve a cobra na tela
  write_snake proc
    push_all

    xor DX, DX                      ; DH = linha, DL = Coluna
    mov SI, offset snake_mapping    ; Armazena as posicoes da cobra em SI
    mov CX, score                   ; Armazena em CX o tamanho da cobra, ou seja, o score

    loop_write_snake:
      cmp word ptr[SI], 0           ; Verifica no array de posicoes da cobra se todas as posicoes ja foram desenhadas
      je exit_write_snake           ; Se for sai da proc

      mov DX, [SI]                  ; armazena a posicao em questao em SI
      call position_to_coord        ; Converte o valor da posicao em coordenadas i, j
      mov AL, snake_char
      mov BL, snake_color
      add SI, 2                     ; Incrementa para a proxima posicao
      call write_char               ; Escreve na tela
    loop loop_write_snake           ; Enquanto CX for diferente de zero

    exit_write_snake:
      pop_all
    ret
  endp

  ; Aumenta uma posicao no vetor de posicoes da cobra
  ; A nova posicao ficara atras da cauda
  increase_snake proc
    push_all
    mov SI, offset snake_mapping      ; Armazena o endreco do vetor de posicoes da cobra em SI

    mov AX, 2                         ; Armazena 2 em axis, pois o vetor de posicoes eh word
    mov BX, score                     ; Armazena o score em BX para fazer a multiplicao com AX e encontrar a ultima posicao no vetor
    mul BX

    add SI, AX                        ; Vai para a posicao apos a cauda 
    sub SI, 2                         ; Retorna para cauda

    add_position_snake:

    mov DX, word ptr[SI]              ; Armazena a posicao da cauda
      cmp axis_to_inc, 'u'            ; Verifica se a cobra esta subindo 
      je increase_u_snake

      cmp axis_to_inc, 'r'            ; Verifica se a cobra esta indo para direita
      je increase_r_snake

      cmp axis_to_inc, 'd'            ; Verifica se a cobra esta indo para baixo
      je increase_d_snake

      cmp axis_to_inc, 'l'            ; Verifica se a cobra esta esquerda
      je increase_l_snake

    increase_u_snake:
      add DX, mapping_j_end           ; Se a cobra estiver subindo, deve ser adionada na posicao atual dela o total de colunas da tela para ir na ultima posicao
      jmp exit_increase_snake

    increase_r_snake:
      dec DX                          ; Se estiver indo para direita, deve ser somada um para ir para a ultima posicao
      jmp exit_increase_snake

    increase_d_snake:
      sub DX, mapping_j_end           ; Se estiver descendo, deve ser subtraido o total de colunas para ir na ultima posicao
      jmp exit_increase_snake

    increase_l_snake:
      inc DX                          ; Se a cobre estiver indo para esquerda, deve ser adicionado um para ir na ultima posicao
      jmp exit_increase_snake    

    exit_increase_snake:
      add SI, 2                         ; Volta para a posicao apos a cauda
      mov word ptr[SI], DX              ; Seta a nova posicao da cauda
      pop_all
    ret
  endp

  ; Converte a posicao armazenada em DX para coordenadas i, j
  ; Retorno -> DH: i, DL: j
  position_to_coord proc  
    push AX
    push BX     
    push CX
            
    mov CX, DX              ; Salva o valor de DX
    xor DX, DX              ; Zera DX para nao interferir na div
 
    mov AX, CX              ; Valor recebido como dividendo
    mov BX, mapping_j_end   ; Tamanho da coluna como divisor
    div BX            
    
    mov DH, AL              ; Armazena o valor da linha em DH 
     
    mov AX, mapping_j_end   ; Armazena o tamanho da coluna como dividendo
    mul DH                  ; Tamanho da coluna * linhas
     
    mov BX, CX              ; Armazena o valor recebido em BX
    sub BX, AX              ; Subtrai valor recebido - tamanho_colunas * linhas
    mov DL, BL              ; Armazena o J
                   
    pop CX
    pop BX
    pop AX
    ret
  endp

  ; Desenha uma comida na teal
  write_food proc
    push_all

    food_is_at_some_body_part:                ; Tag para voltar quando a comida nascer em alguma parte do corpo da cobra
      call generate_food                      ; Gera uma posicao i, j para a comida

    mov SI, offset snake_mapping              ; Armazena as posicoes da cobre em SI
    
    loop_write_food:
      mov DX, word ptr[SI]                    ; DX recebe a posicao atual

      cmp DX, 0                               ; Se for 0 significa que varreu todas as posicao
      jz valid_food                           ; Se varreu todas as posicoes e as coordenadas na comida nao bateram com alguma parte do corpo, significa que eh uma posicao valida para comida

      call position_to_coord                  ; Converte a posicao armazenada em DX para coordenadas i, j
      
      cmp DH, food_i                          ; Compara a coordenada i da parte do corpo atual com a coordenada i da comida
      jne next_iter_loop_write_food           ; Se nao forem iguais, significa que essa parte do corpo esta ok | se for igual vai para verificao do j

      cmp DL, food_j                          ; Compara a coordenada j da parte do corpo atual com a coordenada j da comiga
      je food_is_at_some_body_part            ; Se ambas as coordenadas i, j do corpo forem iguais a da comida, a comida vai ser gerada novamente

      next_iter_loop_write_food:
        add SI, 2                             ; Incrementa SI para ir para proxima parte do corpo da cobra
    jmp loop_write_food

    valid_food:                               ; Desenha a comida na tela
      mov AL, food_char
      mov BL, food_color
      mov DH, food_i
      mov DL, food_j
      call write_char

    pop_all
    ret
  endp

  ; Desenha os zeros do score na tela
  write_zeros_score proc
    push_all

    mov AL, '0'
    xor DH, DH
    mov BL, font_color
    mov DL, edges_j_half - 1

    xor CX, CX
    mov CX, 4
    loop_write_zeros_score:
      call write_char 
      inc DL
      loop loop_write_zeros_score
    
    pop_all
    ret
  endp

  ; Desenha o score na tela
  write_score proc
    push_all

    mov AX, score                       ; AX recebe o valor a ser escrito
    mov BX, 10                          ; divisoes sucessivas por 10
    xor CX, CX                          ; contador de digitos

    loop_div_uint16_write_score:
      xor DX, DX                        ; zerar DX pois o dividendo eh DXAX
      div BX                            ; divisao para separar o digito em DX
      
      push DX                           ; empilhar o digito
      inc CX                            ; incrementa o contador de d?gitos
      
      cmp AX, 0                         ; AX chegou a 0
      jnz loop_div_uint16_write_score   ; enquanto AX diferente de 0 salte para LACO_DIV
            
    loop_write_dig_score:   
      pop DX                            ; desempilha o digito   
      add DL, '0'                       ; converter o digito para ASCII
      
      mov AL, DL                        ; Armazena o digito a ser escrito
      mov DH, 0                         ; Linha onde o digito vai ser escrito
      mov DL, score_j_init              ; Coluna inicial onde o digito vai ser escrito
      add DL, 4                         ; quantidade maxima de digitos
      sub DL, CL                        ; Subtrai a quantidade de digitos para encontrar a posicao correta
      mov BL, font_color
      call write_char 

      loop loop_write_dig_score      ; decrementa o contador de d?gitos

    pop_all
    ret
  endp


  ; #################################### I/O ####################################  

  ; 16H
  ; Le um caractere do teclado e armazena em AL
  ; NAO SALVA CONTEXTO NEM RETORNA
  read_char proc
    mov AH, 01h                 ; Verifica se alguma tecla foi presionada
    int 16h
    jnz  save_key_read_char     ; Se foi va para
    jmp exit_read_char          ; Se nao foi sai da proc

    save_key_read_char:
      mov ah, 00h               ; Le a tecla pessionada e armazena em AL
      int 16h

      cmp AL, 0                 ; Compara AL com 0 para verificar se uma tecla direcional foi pressionada
      jz arrow_was_pressed      ; Se foi, o valor da tecla fica em AH, portanto deve ser trocado com Al
      jnz exit_read_char        ; Se nao foi pressionado, sai do metodo

    arrow_was_pressed:
      xchg AH, AL               ; Troca AL por AH
      
    exit_read_char:
    ret
  endp

  ; NAO SALVA CONTEXTO NEM RETORNA
  read_enter proc
    loop_read_enter:
      call read_char        ; Le o caractere do teclado e armazena em AL
      cmp AL, enter_key_hex ; Verifica se eh um enter
      jne loop_read_enter   ; Fica preso ate apertar enter
    xor AL, AL              ; Limpa o registrador AL para evitar que o valor seja lido diversas vezes 
    ret                     ; Desempilha IP
  endp

  ; Fica lendo o teclado ate que a tecla pressionada seja uma das que esteja armazenas em target_keys
  read_target_keys proc
    push BX
    push SI
    loop_read_target_keys:
      mov SI, offset target_keys  ; Endereco base de target_keys 
      xor BX, BX                  ; Zera incremento

      call read_char                ; Le o caractere do teclado e armazena em AL
      loop_read_target_keys_comp:
        add SI, BX                  ; Vai para o proximo caractere
        cmp byte ptr [SI], AL       ; Verifica o caractere lido com os caracteres do vetor
        je exit                     ; Encontrou o caractere desejado
        jne loop_read_target_keys_inc

      loop_read_target_keys_inc:
        inc BX                          ; Incremento de iteracao  
        cmp BX, target_keys_len         ; Comparacao para verificar todo os digitos
        jne loop_read_target_keys_comp  ; Volta o loop se n verificou todos os digitos
        jg loop_read_target_keys        ; Volta o loop se n eh um digito desejado
    exit:
      pop SI
      pop BX
    ret
  endp

  ; Para o usuario navegar no menu principal
  read_menu proc
      call read_target_keys                   ; Le as setas e enter

      cmp AL, up_key_hex                      ; Se for a seta para cima
      je up_key_handler                       ; Va para up_key_handler

      cmp AL, down_key_hex                    ; Se for seta para baixo
      je down_key_handler                     ; Va para down_key_handler
      
      cmp AL, enter_key_hex                   ; Se for enter
      je read_menu_exit
    
    up_key_handler:
      mov menu_selected_option_index, 0     ; Seta para 0 a posicao do menu
      mov menu_unselected_option_index, 1   ; Posicao nao selecionada
      jmp read_menu_exit
    down_key_handler:
      mov menu_selected_option_index, 1     ; Seta para 1 a posicao do menu
      mov menu_unselected_option_index,0    ; Posicao nao selecionada
      jmp read_menu_exit
    read_menu_exit:                         ; Encerra o loop
    ret                                     ; Desempilha IP
  endp

  ; Realiza um delay sem a necessidade de ficar preso
  delay_without_int proc          
    push_all

    ; 1 tick tem 55 ms
    ; Interrupcao para pegar o clock
    ; Retorna em CX:DX
    ; DX eh a parte mais baixa

    cmp ticks, 0                        ; Verifica a quantidade de ticks que passaram
    je set_ticks_delay                  ; Se for 0, seta os ticks atuais do SO
    jmp cmp_ticks_delay                 ; Se for diferente de 0, compara os ticks setados com os atuais

    ; Salva os ticks ao chamar a proc
    set_ticks_delay:
      mov AH, 00H
      int 1AH  
      mov ticks, DX                     ; Salva os ticks na variavel

    cmp_ticks_delay:          
      mov AH, 00H
      int 1AH         

      sub DX, ticks                     ; Subtrai os ticks atuais dos ticks setados anteriormente

      mov AX, 55                        ; valor de um tick em ms
      mul DX                            ; Multiplica os ticks por 55 para encontrar o tempo decorrido em ms

      cmp AX, interval_delay            ; Compara o tempo decorrido em ms com o tempo setado na variavel interval_delay
      jge delay_finish                  ; Se o tempo atual em ms for maior que o setado, significa que o delay passou
      jmp exit_delay                    ; Se nao, sai do loop

    delay_finish:
      mov flag_delay, true              ; Caso o delay tenha passado, seta a flag_delay para comparacoes
      mov ticks, 0                      ; Reseta os ticks para futuras comparacoes

    exit_delay:    
      pop_all
      ret
  endp

  ; ################################## HANDLERS #################################

  ; Realiza a leitura do teclado o respectivo tratamento quando estiver no menu
  handler_read_menu proc
    push_all
    loop_handler_read_menu:
      call read_menu                  ; Realiza a leitura das teclas do menu

      cmp AL, up_key_hex              ; Compara se for a tecla direcional para cima
      je handler_read_menu_up_key

      cmp AL, down_key_hex            ; Compara se for a tecla direcional para baixo
      je handler_read_menu_down_key
      
      cmp AL, enter_key_hex           ; Compara se for enter
      je handler_read_menu_exit

      handler_read_menu_up_key:
        call write_brackets_menu      ; Redesenha os colchetes para ficar na opcao selecionada
        jmp loop_handler_read_menu
      handler_read_menu_down_key:
        call write_brackets_menu      ; Redesenha os colcheter para ficar na posicao desenhada
        jmp loop_handler_read_menu

      handler_read_menu_exit:
        mov DL, menu_selected_option_index  ; Verifica a posicao da opcao selecionada
        cmp DL, 0                           ; Se for a primeira, abre o jogo
        je open_game
        cmp DL, 1                           ; Se for a segunda, fecha o programa
        je exit_game

    exit_game:
      call finish_program

    open_game:
      mov current_page, game_page           ; Move a pagina atual para a pagina do jogo
      set_page                              ; Seta a pagina atual

    pop_all
    ret
  endp

  ; Realiza a leitura das teclas na tela do jogo
  handler_game proc
    push_all

    call read_target_keys             ; Realiza a leitura das teclas

    cmp AL, down_key_hex              ; Compara se for tecla direcional para baixo
    je down_key_handler_game

    cmp AL, right_key_hex             ; Compara se for tecla direcional para direita
    je right_key_handler_game

    cmp AL, left_key_hex              ; Compara se for tecla direcional para esquerda
    je left_key_handler_game

    cmp AL, up_key_hex                ; Compara se for tecla direcional para cima
    je up_key_handler_game

    jmp exit_handler_game             ; Se nao for nenhuma, sai da proc

    down_key_handler_game:
      cmp axis_to_inc, 'u'            ; Quando a cobra estiver indo para baixo o movimento para cima nao eh permito
      je exit_handler_game            ; Portando sai da proc
      mov axis_to_inc, 'd'            ; Caso a cobra esteja indo em outra direcao, muda a direcao para baixo
      jmp exit_handler_game
    
    right_key_handler_game:
      cmp axis_to_inc, 'l'            ; Quando a cobra estiver indo para direita o movimento para esquerda nao eh permitido
      je exit_handler_game            ; Portanto sai da proc
      mov axis_to_inc, 'r'            ; Caso a cobra esteja indo em outra direcao, muda a direcao para direita
      jmp exit_handler_game
    
    left_key_handler_game:
      cmp axis_to_inc, 'r'            ; Quando a cobra estiver indo para esquerda o movimento para direita nao eh permitido
      je exit_handler_game            ; Portanto sai da proc
      mov axis_to_inc, 'l'            ; Caso a cobra esteja indo em outra direcao, muda a direcao para esquerda
      jmp exit_handler_game
    
    up_key_handler_game:
      cmp axis_to_inc, 'd'            ; Quando a cobra stiver indo para cima o movimento para baixo nao eh permitido
      je exit_handler_game            ; Portanto sai da proc
      mov axis_to_inc, 'u'            ; Caso a cobra esteja indo em outra direcao, muda a direcao para cima
    
    exit_handler_game:
      pop_all
    ret
  endp

  ; ################################### LOGICA ##################################

  ; Reseta as variaveis do jogo
  reset_game proc
    push_all                     
    mov axis_to_inc, 'r'                    ; Configura a direcao da cobra para direita              
    mov ticks, 0                            ; Reseta os ticks
    mov flag_delay, 0                       ; Reseta a flag_delay
    mov score, 1                            ; Seta o score para 1

    ; Configura a posicao do score
    mov edges_j_score, edges_j_half
    sub edges_j_score, edges_j_half_score
    inc edges_j_score

    ; Limpa a tela
    mov AH, 06H                             ; Scroll na tela
    mov AL, 0                               ; Toda a tela      
    mov BH, background_color
    xor CX, CX                              ; linha inicial:coluna inicial
    mov DH, mapping_i_end + 1               ; linha final
    mov DL, mapping_j_end + 1               ; Coluna final
    int 10H

    call write_edges                        ; Escreve as molduras

    ; Limpa as posicoes da cobra
    mov SI, offset snake_mapping            ; Armazena o endereco     
    mov CX, snake_len

    loop_reset_game:
      mov byte ptr[SI], 0                   ; Seta a posicao atual da cobra para 0
      inc SI                                ; Incrementa SI para ir para proxima posicao da cobra
    loop loop_reset_game
    
    pop_all
    ret
  endp

  ; NAO SALVA CONTEXTO
  ; SI = Retorna a posicao do vetor que deve ser modificada
  ; AX = Retorna a posicao no vetor de posicoes
  ; DH = recebe coordenada i
  ; DL = recebe coordenada j
  get_mapping_position proc
    add DH, mapping_i_init                      ; Adiciona na linha a linha inicial da tela                 
    add DL, mapping_j_init                      ; Adiciona na coluna atual a coluna inicial da tela

    ; Realiza o calculo: position = i*m + j
    ; i = linha atual -> DH
    ; j = coluna atual -> DL
    ; m = quantidade de colunas -> mapping_j_end

    xor BX, BX
    xor AX, AX

    ; multiplica i pela quantidade de linhas
    ; para encontrar a sua posicao na matriz
    mov BL, DH                                  ; BL = i
    mov AX, mapping_j_end                       ; AX = m

    push DX                                    ; Salva DX pois a multiplicao ira alterar seu valor 
    mul BX                                     ; AX = i * m
    pop DX                                     ; Retorna DX para recuperar as coordenadas i, j

    ; Soma a quantidade de colunas para ficar na posicao correta na matriz
    xor BX, BX
    mov BL, DL                                 ; BL = j -> pois AX possui a parte i*m da equacao
    add AX, BX                                 ; Soma o componente j para encontrar a posicao no vetor -> AX = i*m + j 

    mov SI, offset snake_mapping               ; SI recebe o vetor de posicoes da cobra
    add SI, AX                                 ; Seta o endereco de SI para corresponder com a coordenada i, j passada por parametro
    ret
  endp

  ; NAO SALVA O CONTEXTO
  ; DX: Resultado
  ; BX: Valor maximo do numero randomico
  generate_random_number proc
    push AX
    push BX

    xor DX, DX
    xor AX, AX            ; xor register to itself same as zeroing register
    int 1AH               ; Int 1ah/ah=0 get timer ticks since midnight in CX:DX
    mov AX, DX            ; Use lower 16 bits (in DX) for random value

    xor DX, DX            ; Compute randval(DX) mod 10 to get num
    div BX                ; Divide dx:ax by bx

    pop BX
    pop AX
    ret
  endp

  ; Evita que a comida caia nas bordas
  ; Se isso ocorrer, ajusta a posicao da comida para dentro da tela
  ; NAO SALVA CONTEXTO
  adjust_food_location proc

    ; 0, 0 -> verificar i,j
    ; 0, end

    cmp_i_init_food_location:
      cmp food_i, mapping_i_init            ; Compara a posicao i da comida com a posicao inicial da borda
      jle inc_i_food_location

    cmp_i_end_food_location:
      cmp food_i, mapping_i_end             ; Compara a posicao i da comida com a posicao final da borda
      jge dec_i_food_location

    cmp_j_init_food_location:
      cmp food_j, mapping_j_init            ; Compara a posicao j da comida com a posicao inicial da borda
      jle inc_j_food_location

    cmp_j_end_food_location:
      cmp food_j, mapping_j_end             ; Compara a posicao j da comida com a posicao final da borda
      jge dec_j_food_location

    jmp exit_adjust_food_location         ; Se nenhuma das comparacos for verdadeira, a comida esta em uma posicao valida

    inc_i_food_location:
      mov food_i, mapping_i_init + 1      ; Caso a posicao da comida tenha coincidido com a borda superior, move a comida uma posicao para baixo
      jmp cmp_i_init_food_location        ; Apos verificar a posicao i, volta para verificar as demais
    
    dec_i_food_location:
      mov food_i, mapping_i_end - 1       ; Caso a posicao da comida tenha coincido com a borda inferior, move a comida uma posicao para cima
      jmp cmp_i_end_food_location          ; Apos verificar a posicao i, volta para verificar as demais
    
    inc_j_food_location:
      mov food_j, mapping_j_init + 1      ; Caso a posicao da comida tenha coincidido com a borda esquerda, move a comida uma posicao para direita
      jmp cmp_j_init_food_location         ; Apos verificar a posicao j, volta para verificar as demais
    
    dec_j_food_location:
      mov food_j, mapping_j_init - 1      ; Caso a posicao da comida tenha coincidido com a borda direita, move a comida uma posicao para esquerda
      jmp cmp_j_end_food_location          ; Apos verificar a posicao j, volta para verificar as demais

    exit_adjust_food_location:
    ret
  endp

  ; Gera uma nova posicao i, j para a comida
  generate_food proc
    push_all
      mov BX, mapping_i_end         ; Seta o valor maximo da linha para ser gerado um valor randomico
      call generate_random_number   ; Gera o valor randomico
      mov food_i, DL                ; Seta a posicao i da comida para o valor gerado

      mov BX, mapping_j_end         ; Seta o valor maximo da coluna para ser gerado um valor randomico
      call generate_random_number   ; Gera o valor randomico
      mov food_j, DL                ; Seta a posicao j da comida para o valor gerado

      call adjust_food_location     ; Ajusta a posicao da comida se necessario

    pop_all
    ret
  endp

  ; Limpa a cauda da cobra
  clear_snake_tail proc
    push_all
      mov AL, ' '                 ; Caractere a ser escrito na ultima posicao
      mov CX, 1                   ; Quantidade de vezes que o caractere vai ser escrito
      mov BL, background_color
      call get_tail_coord         ; Procura pela posicao da cauda

      cmp DH, mapping_i_init      ; Verifica se a posicao i a ser limpa eh a borda supeior 
      jz exit_clear_snake_tail    ; Caso isso ocorra sai da proc, se nao a borda seria apagada
      cmp DH, mapping_i_end       ; Verifica se a posicao i a ser limpa eh a borda inferior
      je exit_clear_snake_tail    ; Caso isso ocorra sai da proc, se nao a borda seria apagada

      cmp DL, mapping_j_init      ; Verifica se a posicao j a ser limpa eh a borda da esquerda
      jz exit_clear_snake_tail    ; Caso isso ocorra sai da proc, se nao a borda seria apagada
      cmp DL, mapping_j_end       ; Verifica se a posicao j a ser limpa eh a borda da direita
      je exit_clear_snake_tail    ; Casso isso ocorra sai da proc, se nao a borda seria apagada

      call write_char             ; Escreve o caractere ' '

    exit_clear_snake_tail:
      pop_all
    ret
  endp

  ; Procura pela cauda da cobra
  ; Retorna -> DH = linha | DL = coluna
  get_tail_coord proc
    push AX
    push BX
    push SI
    mov SI, offset snake_mapping        ; Armazena as posicoes da cobra em SI

    loop_get_snake_coord:
      cmp word ptr[SI], 0               ; Se for 0, significa que chegou na posicao apos a cauda
      je find_snake_coord
      add SI, 2                         ; Caso nao seja 0, incrementa para proxima posicao
      jmp loop_get_snake_coord

      find_snake_coord:
        sub SI, 2                       ; Volta para o rabo, pois passou uma posicao
        mov DX, word ptr[SI]            ; Armazena o valor em DX para encontrar as coordenadas i, j
        call position_to_coord          ; Procura pelas coordenadas i, j

    pop SI
    pop BX
    pop AX
    ret
  endp

  ; Movimenta a cobra de acordo com axis_to_inc
  move_snake proc
    push_all

    mov SI, offset snake_mapping          ; Armazena as posicoes da cobra em SI
    mov AX, word ptr[SI]                  ; Salva a cabeca da cobra em AX

    mov CX, score                         ; Armazena o tamanho do corpo da cobra em CX

    cmp axis_to_inc, 'u'                  ; Verifica se a cobra esta indo para cima
    je inc_u_snake_position

    cmp axis_to_inc, 'r'                  ; Verifica se a cobra esta indo para direita
    je inc_r_snake_position

    cmp axis_to_inc, 'd'                  ; Verifica se a cobra esta indo para baixo
    je inc_d_snake_position

    cmp axis_to_inc, 'l'                  ; Verifica se a cobra esta indo para esquerda
    je inc_l_snake_position

    inc_u_snake_position:
      sub word ptr[SI], mapping_j_end     ; Se a cobra estiver indo para cima, decrementa a cabeca com a quantidade de colunas para ir uma posicao para cima
      jmp increase_snake_position
    
    inc_r_snake_position:
      inc word ptr[SI]                    ; Se a cobra estiver indo para direita, incrementa a cabeca em 1 para ir uma posicao para direita
      jmp increase_snake_position

    inc_d_snake_position:
      add word ptr[SI], mapping_j_end     ; Se a cobra estiver indo para baixo, incrementa a cabeca com a quantidade de colunas para ir uma posicao para baixo
      jmp increase_snake_position

    inc_l_snake_position:
      dec word ptr[SI]                    ; Se a cobra estiver indo para esquerda, decrementa 1 para ir uma posicao para esquerda

    increase_snake_position:
      cmp score, 1                        ; Se a cobra tiver so cabeca, sai da proc
      je exit_move_snake
      dec CX                              ; Decrementa CX para desconsiderar a cabeca
    
    loop_increase_snake_position:
      add SI, 2                           ; Vai para proxima posicao da cobra
      mov BX, word ptr[SI]                ; Salva o valor da posicao em AX
      sub AX, BX                          ; Faz a diferenca da posicao anterior (AX) com a atual (BX) para encontrar a quantidade que a cobra deve andar
      mov DX, word ptr[SI]                ; Salva a posicao atual
      add word ptr[SI], AX                ; Incrementa a posicao atual com a diferenca encontrada
      mov AX, DX                          ; AX recebe a posicao atual sem o incremento da diferenca
    loop loop_increase_snake_position
      
    exit_move_snake:
      pop_all
    ret
  endp

  ; Seta a posicao da cobra de acordo com os valores em DX
  ; Recebe em DH a linha
  ; Recebe em DL a coluna
  set_snake_position proc
    push_all
      call get_mapping_position           ; Gera a posicao de acordo com i, j
      mov SI, offset snake_mapping        ; Armazena o vetor de posicoes em SI
      mov word ptr[SI], AX                ; Seta a posicao da cobra
    pop_all
    ret
  endp

  ; NAO SALVA CONTEXTO
  ; Verifica se ocorreram colioes entre o corpo da cobra ou as bordas
  ; AL = true -> ocorreu colisao
  ; AL = false -> sem colisao
  check_collisions proc
    xor AL, AL

    mov SI, offset snake_mapping          ; Armazena o vetor de posicoes em SI
    mov DX, word ptr[SI]                  ; Salva o valor da posicao em DX para encontrar as coordenadas i, j
    call position_to_coord

    cmp DH, edges_i_init                  ; Verifica se a posicao em questao esta na borda superior
    je game_over_check_collisions

    cmp DH, edges_i_end                   ; Verifica se a posicao esta na borda inferior
    je game_over_check_collisions

    cmp DL, edges_j_init                  ; Verifica se a posicao esta na borda da esquerda
    je game_over_check_collisions

    cmp DL, edges_j_end
    je game_over_check_collisions         ; Verifica se a posicao esta na borda da direita

    mov DX, word ptr[SI]                  ; Armazena o valor da cabeca novamente pois este foi alterado ao chamar a proc position_to_coord
    add SI, 2                             ; Desconsidera a cabeca pois ela nunca foi colidir com ela mesma
    loop_check_body_parts:
      cmp word ptr[SI], DX                ; Compara a posicao atual com a cabeca
      je game_over_check_collisions       ; Se forem iguais ocorreu uma colisao

      cmp word ptr[SI], 0                 ; Compara a posicao do vetor com zero para saber se chegou na ultima posicao
      jz exit_check_collisions

      add SI, 2                           ; Vai para proxima posicao
      loop loop_check_body_parts
    
    jmp exit_check_collisions

    game_over_check_collisions:
      mov AL, true

    exit_check_collisions:
    ret
  endp

  ; NAO SALVA CONTEXTO
  ; Verifica se a cabeca se encontra na mesma posicao que a comida
  ; Retorna AL = true -> se encontrar comida
  ;         AL = 0    -> se nao encontrar comida
  check_food proc
    xor AX, AX

    mov SI, offset snake_mapping        ; SI recebe o vetor de posicoes da cobra
    mov DX, word ptr[SI]                ; Salva a posicao da cabeca em DX
    call position_to_coord              ; Converte o valor da cabeca para coordenadas i,j 

    cmp DH, food_i                      ; Compara a coordenada i da cabeca com a coordenada i da comida
    je cmp_j_check_food                 ; Se forem iguais verifica a coordenada j
    jmp exit_check_food                 ; Se for diferentes a comida e a cabeca se encontram em posicoes diferentes, portando, sai da proc

    cmp_j_check_food:
      cmp DL, food_j                    ; Compara a coordenada j da cabeca com a coordenada j da comida
      je found_food                     ; Se for iguais significa que a cabeca esta na mesma posicao que a comida
      jmp exit_check_food               ; Se nao, estao em posicoes diferentes e sai da proc

    found_food:
      mov AL, true

    exit_check_food:
    ret
  endp


  ; #################################### MAIN ###################################

  inicio:                                 
    call init_segments
    call setup_video

    ; Escreve o menu
    mov current_page, menu_page
    set_page
    call write_menu
    call write_brackets_menu

    ; Escreve a pagina de game over
    mov current_page, game_over_page
    set_page
    call write_game_over

    ; Escreve a tela do jogo
    mov current_page, game_page
    set_page
    call write_edges

    ; Escreve a pagina do titulo
    mov current_page, title_page
    set_page
    call write_title
    write_authors
    
    ; Aguarda na pagina do titulo o usuario apertar enter
    call read_enter

    ; Tag para voltar ao menu apos o game over
    menu_tag:
      mov current_page, menu_page ; Seta a pagina atual a pagina do menu
      set_page
      call handler_read_menu      ; Verifica as inputs do usuario

    ; Configura a primeira posicao da snake
    mov DH, head_i
    mov DL, head_j
    call set_snake_position
    call write_snake

    call write_food               ; Escreve a primeira comida
    call write_zeros_score        ; Escreve os zeros do score
    call write_score              ; Escreve o valor inicial do score, no caso, 1

    main_loop:                    ; Loop do jogo
      call check_collisions       ; Verifica se tem colisoes
      cmp AL, true                ; Se tiver pula paga game_over
      je game_over

      call clear_snake_tail       ; Limpa a cauda da cobra
      call move_snake             ; Movimenta a cobra
      call write_snake            ; Desenha a nova posicao da cobra

      xor BX, BX
      mov BL, axis_to_inc         ; Armazena a posicao atual da direcao da cobra
      mov flag_delay, false
      loop_delay_a_init:
        cmp BH, false             ; Compara BH com false, esse valor eh setado apos o usuario escolher uma posicao difente da atual, isso eh feito para evitar direcoes invalidas
        jz call_handler_game      ; Se for falso, verifica a input do usuario
        jnz skip_handler_game     ; Se for verdadeiro, pula a input do usuario
 
        call_handler_game:
          call handler_game       ; Verifica a input do usuario
        
        cmp BL, axis_to_inc       ; Compara BL (posicao antiga) com a nova posicao
        jne already_make_movement ; Se forem diferentes, significa que o usuario ja realizou um movimento
        je skip_handler_game      ; Se forem iguais, o usuario ainda nao fez um movimento e pula para skip_handler_game para nao setar BH (flag para verificar se ocorreu movimento)

        already_make_movement:
          mov BH, true            ; Indica que o usuario ja realizou um movimento

        skip_handler_game:
          call delay_without_int  ; Chama o delay sem interrupcao
          cmp flag_delay, false   ; Verifica se o delay ja terminou
        je loop_delay_a_init      ; Se nao terminou, volta para o loop
      
      call check_food             ; Verifica se a cabeca da cobra se encontra na mesma posicao que a comida
      cmp AL, true                ; Se estiver, incrementa o score
      je inc_score

      jmp main_loop               ; Volta para o loop principal

    inc_score:
      call increase_snake         ; Incrementa o tamanho da cobra
      inc score                   ; Incrementa o score
      call write_food             ; Escreve a comida em uma nova posicao
      call write_score            ; Escreve o novo score
      jmp main_loop               ; Volta para o loop principal
    
    game_over:
      call reset_game                   ; Reseta as variaveis do jogo e limpa a tela do jogo
      mov current_page, game_over_page  ; Seta a pagina atual como sendo a pagina de game over
      set_page
      call read_enter                   ; Aguarda o usuario pressionar enter
      jmp menu_tag                      ; Pula para menu_tag
      
  call finish_program                   ; Finaliza o programa
end inicio                              ; ACABOU GRAZADEUS
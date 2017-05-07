library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

ENTITY UART IS PORT 
	(	 
		-- Module signals
		DATAREADY	: out std_logic;
		COMMAND		: out unsigned(7 downto 0);
		DATA			: out unsigned(31 downto 0);
	
		-- FPGA External signals
		RX				: in std_logic;
		TX				: out std_logic;
		
		--- DEBUG
		LED 		: out unsigned(7 downto 0);
		
		-- System
		RST_N			: in std_logic;
		MCLK			: in std_logic
	);
END ENTITY;

ARCHITECTURE ARCH of UART is

	-- Machine d'état de traitement bits réception UART
	TYPE 		SM_UART_State	IS (SM_UART_WAIT, SM_UART_WAIT1, SM_UART_WAIT2, SM_UART_END);
	SIGNAL 	SM_UART	: SM_UART_State;
	
	-- Machine d'état de traitement des bytes reçus
	TYPE 		SM_BYTES_State	IS (SM_BYTES_IDLE, SM_BYTES_PROCESS);
	SIGNAL 	SM_BYTES	: SM_BYTES_State;
	SIGNAL 	CMDBUF	: unsigned (7 downto 0) := x"20";
	SIGNAL 	DATABUF	: INTEGER;
	
	-- Machine d'état d'assemblage des commandes
	TYPE 		SM_CMD_State IS (SM_CMD_WAIT_CMD, SM_CMD_WAIT_ARG, SM_CMD_WAIT_ARG_OR_CR, SM_CMD_WAIT_CR);
	SIGNAL 	SM_CMD	: SM_CMD_State;
	
	-- Compteur pour 115200 bit/s
	SIGNAL TIME_COUNT : INTEGER;
	SIGNAL BIT_COUNT : INTEGER;
	CONSTANT WAIT1VAL : INTEGER := 1302;
	CONSTANT WAIT2VAL : INTEGER := 868;
	
	--- Reset counter
	SIGNAL COUNTER : INTEGER := 0;
	SIGNAL iRST_N	: std_logic := '0';
	
	--- Always latch external signals
	SIGNAL RX_LATCHED	: std_logic;
	
	---
	SIGNAL BYTE 		: unsigned (7 downto 0);
	SIGNAL BYTE_READY	: std_logic;
	
BEGIN
	
	--- RESET
	PROCESS (MCLK)
	BEGIN
		IF rising_edge(MCLK) THEN
			IF COUNTER < 10000 THEN
				COUNTER <= COUNTER + 1;
				iRST_N <= '0';
			ELSE
				iRST_N <= '1' AND RST_N;
			END IF;
		END IF;	
	END PROCESS;
	
	PROCESS (iRST_N, MCLK)
	BEGIN
		IF iRST_N='0' THEN
		
			BYTE_READY <= '0';
			LED <= x"00";
			RX_LATCHED <= '1';
			SM_UART <= SM_UART_WAIT;
			SM_BYTES <= SM_BYTES_IDLE;
			SM_CMD <= SM_CMD_WAIT_CMD;
			
		ELSIF rising_edge(MCLK) THEN
			
			RX_LATCHED <= RX;
			
			CASE SM_UART is

				WHEN SM_UART_WAIT =>
					BYTE_READY <= '0';
					--- Wait for a start bit
					IF RX_LATCHED = '0' THEN
						--- Start bit received
						TIME_COUNT <=0;
						SM_UART <= SM_UART_WAIT1;
					END IF;
				
				WHEN SM_UART_WAIT1 =>				
					--- Wait to be in the middle of the first bit
					TIME_COUNT <= TIME_COUNT + 1;
					IF TIME_COUNT = WAIT1VAL THEN
						--- Sample the first bit
						BYTE(7) <= RX_LATCHED;
						TX <= RX_LATCHED;
						--- Reset counter value for the next bit
						TIME_COUNT <=0;
						BIT_COUNT <=1;
						SM_UART <= SM_UART_WAIT2;						
					END IF;	
				
				WHEN SM_UART_WAIT2 =>
					--- Wait to be in the middle of the next bit
					TIME_COUNT <= TIME_COUNT + 1;
					IF TIME_COUNT = WAIT2VAL THEN
						--- Sample the next bit
						BYTE <= RX_LATCHED & BYTE(7 DOWNTO 1);
						TX <= RX_LATCHED;
						--- Reset counter value for the next bit
						TIME_COUNT <= 0;
						BIT_COUNT <= BIT_COUNT + 1;				
						---
						IF BIT_COUNT = 7 THEN
							SM_UART <= SM_UART_END;
						END IF;			
					END IF;			
						
				WHEN SM_UART_END =>
					--- Wait to be in the middle of the stop bit
					TIME_COUNT <= TIME_COUNT + 1;
					IF TIME_COUNT = WAIT2VAL THEN						
						BYTE_READY <= '1';
						SM_UART <= SM_UART_WAIT;						
					END IF;				

			END CASE;
			
			---------------------------------
			CASE SM_BYTES is
			
				WHEN SM_BYTES_IDLE =>
				
					DATAREADY <= '0';	
					
					IF BYTE_READY = '1' THEN
						SM_BYTES <= SM_BYTES_PROCESS;
					END IF;
					
				WHEN SM_BYTES_PROCESS =>
		
					CASE SM_CMD IS
					
						WHEN SM_CMD_WAIT_CMD =>
							-- On attend une commande
							IF BYTE = x"74" OR BYTE = x"73" OR BYTE = x"63" OR BYTE = x"30" OR BYTE = x"31" THEN
								--- Si commande sans argument, la stocker et...
								
								CMDBUF <= BYTE;
								--- ... aller dans l'état d'attente retour chariot
								SM_CMD <= SM_CMD_WAIT_CR;
								
							ELSIF BYTE = x"66" THEN
						
								--- Si commande avec argument, la stocker et...
								CMDBUF <= BYTE;
								--- ... aller dans l'état d'attente d'argument
								DATABUF <= 0;
								SM_CMD <= SM_CMD_WAIT_ARG;
								
							ELSIF BYTE = x"0D" THEN
							
								--- Si CR sans commande ou autre caractère on reste dans l'état SM_CMD_WAIT_CMD
							END IF;
							
						WHEN SM_CMD_WAIT_CR =>
							--- On attend un CR
							IF BYTE = x"0D" THEN							
								-- CR reçu tout est OK
								DATAREADY <= '1';
								COMMAND <= CMDBUF;
								LED <= CMDBUF;
								--
								SM_CMD <= SM_CMD_WAIT_CMD;
							ELSE
								--- Tout autre caractère reçu est une erreur
								SM_CMD <= SM_CMD_WAIT_CMD;
							END IF;

						WHEN SM_CMD_WAIT_ARG =>
							--- On attend un argument (uniquement numérique, entre '0' et '9')
							IF BYTE >= x"30" AND BYTE <= x"39" THEN							
								--- Mettre à jour la valeur du buffer d'argument
								DATABUF <= 10 * DATABUF + TO_INTEGER(BYTE) - 48;
								---
								SM_CMD <= SM_CMD_WAIT_ARG_OR_CR;
							ELSE
								--- Tout autre caractère reçu est une erreur
								SM_CMD <= SM_CMD_WAIT_CMD;
							END IF;
							
						WHEN SM_CMD_WAIT_ARG_OR_CR =>
							--- On attend un argument (uniquement numérique, entre '0' et '9') ou un CR
							IF BYTE >= x"30" AND BYTE <= x"39" THEN			
								--- Mettre à jour la valeur du buffer d'argument
								DATABUF <= 10 * DATABUF + TO_INTEGER(BYTE) - 48;
								---
								SM_CMD <= SM_CMD_WAIT_ARG_OR_CR;
							ELSIF BYTE = x"0D" THEN
								-- CR reçu tout est OK
								DATAREADY <= '1';
								COMMAND <= CMDBUF;
								DATA <= TO_UNSIGNED(DATABUF, 32);
								LED <= TO_UNSIGNED(DATABUF, 8); --CMDBUF;
								--
								SM_CMD <= SM_CMD_WAIT_CMD;
							ELSE
								--- Tout autre caractère reçu est une erreur
								SM_CMD <= SM_CMD_WAIT_CMD;
							END IF;
				
					END CASE;
					
					--
					SM_BYTES <= SM_BYTES_IDLE;
							
			END CASE;				
			
		END IF;	
	END PROCESS;

END ARCH;

								
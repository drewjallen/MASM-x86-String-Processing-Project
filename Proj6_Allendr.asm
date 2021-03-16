TITLE Project 6: String Primitives and Macros    (Proj6_Allendr.asm)

; Author: Drew Allen
; Last Modified: 3/13/21
; OSU email address: Allendr@oregonstate.edu
; Course number/section:   CS271 Section 400
; Project Number:    6             Due Date:  3/14/21
; Description: This program implements two macros for string processing and tests them
;				with several procedures
				

INCLUDE Irvine32.inc
;-------------------------------------------------------------------------------------
; Name: mGetString
;
; Gets a string input from the user and stores it in memory
; 
; Preconditions: 
;		arrayBuffer has been declared and the SIZEOF is known
;
; Receives:
;		OFFSET prompt
;		OFFSET inputBuffer
;		inputLength (value)
;		OFFSET bytesRead
;
; Returns: 
;		inputBuffer = inputted string
;		bytesRead = number of bytes read in from user
;------------------------------------------------------------------------------------

mGetString MACRO prompt, inputBuffer, inputLength, bytesRead
	PUSH	EDX
	PUSH	ECX
	PUSH	EAX
	
	MOV		EDX, prompt
	CALL	WriteString

	MOV		EDX, inputBuffer
	MOV		ECX, inputLength
	CALL	ReadString
	MOV		bytesRead, EAX
	
	POP		EAX
	POP		ECX
	POP		EDX
ENDM

;-------------------------------------------------------------------------------------
; Name: mDisplayString
;
; Retrieves a string from memory and prints it to the console
; 
; Preconditions: 
;		arrayBuffer has been declared and the SIZEOF is known
;
; Receives:
;		OFFSET storedArray
;
; Returns: 
;		None
;------------------------------------------------------------------------------------
mDisplayString MACRO storedArray
	PUSH	EDX
	
	MOV		EDX, storedArray
	CALL	WriteString
	
	POP		EDX
ENDM


	ARRAYSIZE			 =			10

.data

	openingTitle		BYTE		"PROJECT 6: String Primitives and Macros",0
	author				BYTE		"By Drew Allen",0
	instructionsOne		BYTE		"Please input ten signed decimal integers that can each fit in a 32 bit register.",0
	instructionsTwo		BYTE		"Then this program will display a list of the numbers, their sum, and their average.",0
	userPrompt			BYTE		"Enter a signed integer: ",0
	errorMessage		BYTE		"ERROR: Invalid input. Entry was too large or not a signed number.",0
	tryAgainPrompt		BYTE		"Please try again: ",0
	listMessage			BYTE		"Here are the numbers you entered: ",0
	sumMessage			BYTE		"The sum is: ",0
	averageMessage		BYTE		"The average is: ",0
	goodbyeMessage		BYTE		"Thanks for playing! Goodbye.",0
	spacing				BYTE		", ",0



	userInputBuffer		BYTE		50 DUP(?)
	reverseOutputBuffer	BYTE		50 DUP(?)
	outputBuffer		BYTE		50 DUP(?)
	userDigitsEntered	SDWORD		?
	userArray			SDWORD		ARRAYSIZE DUP(?)
	convertedInput		SDWORD		?
	digitsCounted		SDWORD		?
	sum					SDWORD		?
	average				SDWORD		?



.code
main PROC

	mDisplayString		OFFSET	openingTitle
	CALL	CrLf
	mDisplayString		OFFSET	author
	CALL	CrLf
	mDisplayString		OFFSET	instructionsOne
	CALL	CrLf
	mDisplayString		OFFSET	instructionsTwo
	CALL	CrLf
	CALL	CrLf
	
	; Retrieve ten strings from user and convert to ints
	MOV		ECX, ARRAYSIZE
	MOV		EDI, OFFSET userArray		
	_fillArrayLoop:
		MOV		EAX, 0
		PUSH	OFFSET userDigitsEntered
		PUSH	SIZEOF userInputBuffer
		PUSH	OFFSET convertedInput
		PUSH	OFFSET userPrompt
		PUSH	OFFSET userInputBuffer
		PUSH	OFFSET errorMessage
		CALL	ReadVal
		MOV		EAX, convertedInput
		MOV		[EDI], EAX
		ADD		EDI, 4
		LOOP	_fillArrayLoop
	
	; Display list of numbers entered by user	
	PUSH	LENGTHOF userArray
	PUSH	LENGTHOF outputBuffer
	PUSH	LENGTHOF reverseOutputBuffer
	PUSH	OFFSET	spacing
	PUSH	OFFSET	listMessage
	PUSH	OFFSET	digitsCounted
	PUSH	OFFSET	outputBuffer
	PUSH	OFFSET	reverseOutputBuffer
	PUSH	OFFSET	userArray
	CALL	DisplayList

	; Display sum of all user's ten numbers
	PUSH	LENGTHOF outputBuffer
	PUSH	LENGTHOF reverseOutputBuffer
	PUSH	OFFSET outputBuffer
	PUSH	OFFSET reverseOutputBuffer
	PUSH	LENGTHOF userArray
	PUSH	OFFSET sumMessage
	PUSH	OFFSET userArray
	CALL	DisplaySum

	; Display average of all user's ten numbers
	PUSH	LENGTHOF outputBuffer
	PUSH	LENGTHOF reverseOutputBuffer
	PUSH	OFFSET outputBuffer
	PUSH	OFFSET reverseOutputBuffer
	PUSH	LENGTHOF userArray
	PUSH	OFFSET averageMessage
	PUSH	OFFSET userArray
	CALL	DisplayAverage

	Invoke ExitProcess,0
main ENDP

;-------------------------------------------------------------------------------------
; Name: ReadVal
;
; Retrieves a string from user by calling mGetString, performs a validation to make 
;		sure it can be converted, then stores the integer in memory where it can be
;		accessed and copied into an array
; 
; Preconditions: 
;		memory allocated for storing converted integer
;		prompt and error message strings declared and stored in memory
;		memory allocated for storage of user entered string
;
; Receives:
;		[EBP + 28] OFFSET userDigitsEntered
;		[EBP + 24] SIZEOF userInputBuffer
;		[EBP + 20] OFFSET convertedInput
;		[EBP + 16] OFFSET userPrompt
;		[EBP + 12] OFFSET userInputBuffer
;		[EBP + 8] OFFSET errorMessage
;
; Returns: 
;		convertedInput now has stored integer converted from user's string input
;------------------------------------------------------------------------------------
ReadVal PROC
	PUSH	EBP
	MOV		EBP, ESP
	PUSHAD
	
	; skip past error message
	JMP	_try

	_errorTryAgainRestoreEBX:
		POP		EDX ; EDX was pushed just before being used in multiplication and must be restored before looping back to the error message
	_errorTryAgain:
		mDisplayString [EBP+8]
		CALL	CrLf
	_try:
		mGetString [EBP+16], [EBP+12], [EBP+24], [EBP+28]
	
	;--------------------------------------------------
	; in this converstion loop each character in
	; the user's string is loaded and moved into
	; BL register so EAX can be used for conversion
	; math. EBX is compared with various ASCII values
	; to determine its validity. Conversion of characters
	; is done by subtracting 48 and multiplying factors
	; of ten.
	;---------------------------------------------------
	MOV		ESI, [EBP+12]
	MOV		ECX, [EBP+28]
	MOV		EAX, 0
	MOV		EDX, 0 ; DX == -1: number is negative. == 0: positive. save until end and use to decide of MUL needed on final number
	_conversionLoop:
		PUSH	EAX
		LODSB
		MOV		EBX, 0
		MOV		BL, AL
		POP		EAX
		

		CMP		EBX, 43 ; checking for a '+' sign
		JE		_skipToEnd
		CMP		EBX, 45
		JE		_skipToEndNegative ; checking for a '-' sign

		_notSignSymbol:
			CMP		EBX, 48
			JL		_errorTryAgain
			CMP		EBX, 57
			JG		_errorTryAgain

			SUB		EBX, 48
			PUSH	EDX
			MOV		EDX, 10
			MUL		EDX
			JO		_errorTryAgainRestoreEBX
			ADD		EAX, EBX
			JO		_errorTryAgainRestoreEBX
			POP		EDX
			JMP		_skipToEnd

		_skipToEndNegative:
			MOV		EDX, -1
		
		_skipToEnd:
		LOOP _conversionLoop

	CMP		EDX, -1
	JE		_makeNegative
	JMP		_notNegative

	_makeNegative:
		MUL		EDX ; if the user entered a '-' sign then convert the value to negative with multiplication

	_notNegative:
		MOV		EBX, [EBP+20]
		MOV		[EBX], EAX
	
	POPAD
	POP		EBP
	RET		24
ReadVal ENDP

;-------------------------------------------------------------------------------------
; Name: WriteVal
;
; Retrieves an integer from memory and converts it to its string representation based on
;		ASCII code
; 
; Preconditions: 
;		userArray has been filled with SDWORD values
;		reverseOutput is is uninitialized or filled with null bytes
;		outputBuffer is uninitialized or filled with null bytes
;
; Receives:
;		[EBP + 8 ] SDWORD in userArray
;		[EBP + 16]  OFFSET outputBuffer
;		[EBP + 12] OFFSET	reverseOutputBuffer
;
; Returns: 
;		outputBuffer now has correctly ordered string representing integer
;		stored in memory
;------------------------------------------------------------------------------------
WriteVal PROC
	PUSH	EBP
	MOV		EBP, ESP
	PUSHAD

	MOV		ECX, 0
	MOV		EAX, [EBP + 8] ; integer value to be converted
	MOV		EBX, 1

	CMP		EAX, 0
	JL		_negativeNumber
	JMP		_notNegative

	_negativeNumber:
		MOV		EBX, -1
		INC		ECX

	_notNegative:
		MOV		EDI, [EBP + 12]
	
	;--------------------------------------------------
	; in this converstion loop the integer to be converted
	; is processed into its ASCII form by dividing by factors
	; of 10 and adding back 48. Each converted ASCII value is
	; stored in its place in the string
	;------------------------------------------
	MOV		EDX, 0
	MUL		EBX
	PUSH	EBX
	_conversionLoop:
		MOV		EDX, 0
		MOV		EBX, 10
		DIV		EBX
		PUSH	EAX
		ADD		EDX, 48
		MOV		EAX, EDX
		STOSB
		INC		ECX
		POP		EAX
		CMP		EAX, 0
		JNE		_conversionLoop
	POP		EBX
	CMP		EBX, -1
	JE		_addNegativeSign
	JMP		_noNegativeSign

	_addNegativeSign:
		MOV		AL, 45
		STOSB

	_noNegativeSign:
		PUSH	ECX
		PUSH	[EBP + 16] ; REGULAR OUTPUT BUFFER
		PUSH	[EBP + 12] ; REVERSE OUTPUT BUFFER
		CALL	ReverseString ; String is reveresed for final output as it is stored originally in reverse order

	POPAD
	POP		EBP
	RET		12
WriteVal ENDP

;-------------------------------------------------------------------------------------
; Name: DisplayList
;
; Retrieves an integer from memory and converts it to its string representation based on
;		ASCII code
; 
; Preconditions: 
;		userArray has been filled with SDWORD values
;		reverseOutput is is uninitialized or filled with null bytes
;		outputBuffer is uninitialized or filled with null bytes
;
; Receives:
;		[EBP + 40] LENGTHOF userArray
;		[EBP + 36] LENGTHOF outputBuffer
;		[EBP + 32] LENGTHOF reverseOutputBuffer
;		[EBP + 28] OFFSET	spacing
;		[EBP + 24] OFFSET	listMessage
;		[EBP + 20] OFFSET	digitsCounted
;		[EBP + 16] OFFSET	outputBuffer
;		[EBP + 12] OFFSET	reverseOutputBuffer
;		[EBP + 8] OFFSET	userArray
;
; Postconditions: 
;		writeVal PROC has changed reverseOutputBuffer and outputBuffer
;------------------------------------------------------------------------------------
DisplayList PROC
	PUSH	EBP
	MOV		EBP, ESP
	PUSHAD

	MOV		ECX, [EBP + 40]
	MOV		ESI, [EBP + 8]

	CALL	CrLf
	mDisplayString [EBP + 24] ; display message
	CALL	CrLf

	_displayLoop:
		MOV		EAX, [ESI]
		
		PUSH	[EBP + 12]
		PUSH	[EBP + 32]
		CALL	ClearString ; clear strings at each iteration to prevent unintended over-writes

		PUSH	[EBP + 16]
		PUSH	[EBP + 36]
		CALL	ClearString

		;----------------
		; convert int to 
		; string for output
		;----------------
		PUSH	[EBP + 16]
		PUSH	[EBP + 12]
		PUSH	EAX
		CALL	WriteVal
		
		mDisplayString [EBP + 16]
		mDisplayString [EBP + 28] ; string for formatting
		ADD		ESI, 4
		LOOP	_displayLoop

	POPAD
	POP		EBP
	RET		36
DisplayList ENDP

;-------------------------------------------------------------------------------------
; Name: DisplaySum
;
; Repeatedly ADDs to a running sum for each value in the SDWORD array passed in by reference.
;		Takes that sum, then passes it into writeVal as a stack parameter to be converted into 
;		a string for output 
; 
; Preconditions: 
;		userArray has been filled with SDWORD values
;
; Receives:
;		[EBP + 32] LENGTHOF outputBuffer
;		[EBP + 28] LENGTHOF reverseOutputBuffer
;		[EBP + 24] OFFSET outputBuffer
;		[EBP + 20] OFFSET reverseOutputBuffer
;		[EBP + 16] LENGTHOF userArray
;		[EBP + 12] OFFSET sumMessage
;		[EBP + 8] OFFSET userArray
;
; Postconditions: 
;		writeVal PROC has changed reverseOutputBuffer and outputBuffer
;------------------------------------------------------------------------------------
DisplaySum PROC
	PUSH	EBP
	MOV		EBP, ESP
	PUSHAD

	PUSH	[EBP + 20]
	PUSH	[EBP + 28]
	CALL	ClearString

	PUSH	[EBP + 24]
	PUSH	[EBP + 32]
	CALL	ClearString

	MOV		EAX, 0 ; EAX will hold the running sum, then will be passed as a parameter on
				   ; on the stack
	MOV		ESI, [EBP + 8]
	MOV		ECX, [EBP + 16]

	_sumLoop:
		ADD		EAX, [ESI]
		ADD		ESI, 4
		LOOP	_sumLoop
	
	PUSH	[EBP + 24]
	PUSH	[EBP + 20]
	PUSH	EAX
	CALL	WriteVal

	CALL	CrLf
	CALL	CrLf
	mDisplayString [EBP + 12]
	mDisplayString [EBP + 24]

	POPAD
	POP		EBP
	RET		28
DisplaySum ENDP

;-------------------------------------------------------------------------------------
; Name: DisplayAverage
;
; Repeatedly ADDs to a running sum for each value in the SDWORD array passed in by reference.
;		Takes that sum, then divides it by the number of values in the array. The resulting
;		average is passed into writeVal as a stack parameter to be converted into a string for output
; 
; Preconditions: 
;		userArray has been filled with SDWORD values
;
; Receives:
;		[EBP + 32] LENGTHOF outputBuffer
;		[EBP + 28] LENGTHOF reverseOutputBuffer
;		[EBP + 24] OFFSET outputBuffer
;		[EBP + 20] OFFSET reverseOutputBuffer
;		[EBP + 16] LENGTHOF userArray
;		[EBP + 12] OFFSET averageMessage
;		[EBP + 8] OFFSET userArray
;
; Postconditions: 
;		writeVal PROC has changed reverseOutputBuffer and outputBuffer
;------------------------------------------------------------------------------------
DisplayAverage PROC
	PUSH	EBP
	MOV		EBP, ESP
	PUSHAD


	PUSH	[EBP + 20]
	PUSH	[EBP + 28]
	CALL	ClearString

	PUSH	[EBP + 24]
	PUSH	[EBP + 32]
	CALL	ClearString

	MOV		EAX, 0
	MOV		ESI, [EBP + 8]
	MOV		ECX, [EBP + 16]

	_sumLoop:
		ADD		EAX, [ESI]
		ADD		ESI, 4
		LOOP	_sumLoop
	
	MOV		EDX, 0
	MOV		EBX, [EBP + 16]
	IDIV	EBX

	PUSH	[EBP + 24]
	PUSH	[EBP + 20]
	PUSH	EAX
	CALL	WriteVal

	CALL	CrLf
	CALL	CrLf
	mDisplayString [EBP + 12]
	mDisplayString [EBP + 24]
	CALL	CrLf
	CALL	CrLf

	POPAD
	POP		EBP
	RET		28 ; N equal to the number of bytes of parameters which were pushed on the stack before the CALL statement.
DisplayAverage ENDP

;-------------------------------------------------------------------------------------
; Name: ReverseString
;
; Loads each byte from the backwards string started at the last index, then stores it
; in a second string in the correct order
; 
; Preconditions: 
;		reverseOutputBuffer contains a string to be reversed
;		outputBuffer is uninitialized or filled with null bytes
;
; Receives:
;		[EBP + 16] length of reverseOutputBuffer
;		[EBP + 12] OFFSET	outputBuffer
;		[EBP + 8] OFFSET	reverseOutputBuffer
;
; Returns: 
;		outputBuffer contains the reverse order of reverseOutputBuffer
;------------------------------------------------------------------------------------
ReverseString PROC
	PUSH	EBP
	MOV		EBP, ESP
	PUSHAD

	MOV		ESI, [EBP+8]
	MOV		EDI, [EBP +12]
	MOV		ECX, [EBP+16]
	ADD		ESI, ECX
	DEC		ESI

	;------------------------------------------------------
	; Sets direction flag to pull value from backwards array
	; Clears direction flag to store value in correct order
	;------------------------------------------------------
	_reverseLoop:
		STD
		LODSB
		CLD
		STOSB
		LOOP	_reverseLoop
	
	POPAD
	POP		EBP
	RET		12 ; N equal to the number of bytes of parameters which were pushed on the stack before the CALL statement.
ReverseString ENDP

;-------------------------------------------------------------------------------------
; Name: ClearString
;
; Clears string by iterating through each element and replacing it with a null byte
; 
; Preconditions: 
;		reverseOutputBuffer contains a string to be reversed
;		outputBuffer is uninitialized or filled with null bytes
;
; Receives:
;		[EBP + 12] OFFSET of array to clear
;		[EBP + 8] LENGTHOF array to clear
;
; Returns: 
;		array at OFFSET is now cleared and filled with null bytes
;------------------------------------------------------------------------------------
ClearString PROC
	PUSH	EBP
	MOV		EBP, ESP
	PUSHAD

	MOV		ECX, [EBP + 8]
	MOV		EDI, [EBP + 12]
	MOV		EBX, 0

	_clearLoop:
		MOV		[EDI], EBX
		INC		EDI
		LOOP	_clearLoop
	
	POPAD
	POP		EBP
	RET		8
ClearString ENDP


END main

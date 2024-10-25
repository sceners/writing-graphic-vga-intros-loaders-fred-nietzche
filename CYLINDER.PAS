Program Cylinder_Scroll;

  Const CGA_CharSet_Seg = $0F000;
        CGA_CharSet_Ofs = $0FA6E;
        VGA_Segment = $A000;
        
        ScrollYPos = 80;
        Radius = 30;
        NumSlices = 90;
        AngleInc = 2*Pi / NumSlices;

        Spacing = 4;

        PW = 'Esselete';

        NumXCoords = 300 Div Spacing;
        CharColor = 1;


DispStr : Array[1..149] Of Byte =
(101,147,147,133,140,133,148,133,101,147,191,180,173,169,185,183,101,181,
204,133,178,183,185,169,101,193,188,170,192,191,183,173,138,147,147,133,
140,133,148,133,101,147,147,147,154,147,183,170,147,199,184,183,188,180,
189,179,153,148,147,167,174,184,148,141,120,163,164,142,140,152,164,158,
114,163,164,153,160,147,162,147,101,147,147,133,140,133,198,186,147,193,
188,179,179,133,195,179,101,200,198,183,140,150,168,147,121,147,183,186,
173,177,160,133,126,169,163,149,151,133,195,179,145,204,147,133,140,133,
148,133,152,204,198,180,188,159,148,171,151,184,183,133,186,174,185,185,
159,182,187,170,140 );

NumDispChars = 149;
        CharLength      = 8;
        NumChars        = 256;


  Type  OneChar =Array[1..CharLength] Of Byte;


  Var   ScreenPath : Array[1..8*80] Of Word;
        CurrentLine,
        CurrentArrayLoc  : Integer;
        DispChars   : Array[1..NumDispChars*64] Of Byte;
        CharSet : Array[1..NumChars] Of OneChar;
        Password : String;

        KeyHit : Boolean;
        Int9Vec : LongInt;


  Procedure VideoMode ( Mode : Byte );

    Begin { VideoMode }
      Asm
        Mov  AH,00
        Mov  AL,Mode
        Int  10h
      End;
    End;  { VideoMode }


  Procedure GetChars;

    Var NumCounter,
        ByteCounter,
        MemCounter   :Integer;

    Begin { GetChars }
      MemCounter:=0;
      For NumCounter:=1 To NumChars Do
        For ByteCounter:=1 To CharLength Do
          Begin
            CharSet[NumCounter][ByteCounter]:=Mem[CGA_CharSet_Seg:CGA_CharSet_Ofs+MemCounter];
            Inc(MemCounter);
          End;
    End;  { GetChars }


  Procedure SetColor ( Color, Red, Green, Blue : Byte );

    Begin { SetColor }
      Port[$3C8] := Color;
      Port[$3C9] := Red;
      Port[$3C9] := Green;
      Port[$3C9] := Blue;
    End;  { SetColor }


  Procedure BuildPath;

    Var YCount,
        XCount,
        ArrayPtr  : Integer;
        CurrAngle : Real;

    Begin { BuildPath }
      CurrAngle := Pi;
      ArrayPtr := 1;
      For XCount := 1 To NumXCoords Do
        Begin
          For YCount := 1 To 8 Do
            Begin
              ScreenPath[ArrayPtr] := (ScrollYPos + Round(Radius*Sin(CurrAngle)))*320
                                      + (XCount-1)*Spacing + 1;
              CurrAngle := CurrAngle + AngleInc;
              Inc(ArrayPtr);
            End;
          CurrAngle := CurrAngle - 7*AngleInc;
        End;
    End;  { BuildPath }


  Procedure BuildCharArray;

    Var ShearYCnt,
        ShearXCnt,
        Count,
        ArrayPtr   : Integer;
        TempByte   : Byte;

    Begin { BuildCharArray }
      ArrayPtr := 1;
      For Count := 1 To NumDispChars Do
        Begin
          TempByte := DispStr[Count] - Ord(Password[((Count-1) Mod Length(Password))+1]);
          For ShearXCnt := 1 To 8 Do
            For ShearYCnt := 1 To 8 Do
              Begin
                If Mem[CGA_CharSet_Seg:CGA_CharSet_Ofs+TempByte*8+ShearYCnt-1] And ($80 Shr (ShearXCnt-1)) = 0
                  Then DispChars[ArrayPtr] := 0
                  Else DispChars[ArrayPtr] := CharColor;
                Inc(ArrayPtr);
              End;
        End;
    End;  { BuildCharArray }


  Procedure Cycle;

    Label Wait,Retr,Loop1,Loop2,Continue1,Continue2,Continue3,Continue4,
          Continue5;

    Begin { Cycle }
      Asm
          MOV   AX,VGA_Segment
          MOV   ES,AX
          MOV   DI,(ScrollYPos-Radius)*320
          MOV   CX,160*Radius*2+320

          MOV   DX,3DAh
Wait:     IN    AL,DX
          TEST  AL,08h
          JZ    Wait
Retr:     IN    AL,DX
          TEST  AL,08h
          JNZ   Retr

          XOR   AX,AX
          REP   STOSW

          MOV   BX,CurrentLine
          MOV   CL,3
          SHL   BX,CL
          MOV   DX,BX

          MOV   AX,NumXCoords
Loop1:
          MOV   CX,8
Loop2:
          CMP   Byte Ptr DispChars[BX],0
          JE    Continue2

          PUSH  BX
          {Put Dot}
          SUB   BX,DX
          SHL   BX,1
          MOV   DI,Word Ptr ScreenPath[BX]
{          PUSH  DX
          MOV   DX,CurrentArrayLoc
          SHL   DX,1
          SHL   DX,1
          SUB   DI,DX
          CMP   DI,NumXCoords*Spacing+ScrollYPos*160
          JLE   Continue1

          ADD   DI,NumXCoords*Spacing
Continue1:
          POP   DX }
          MOV   Byte Ptr ES:[DI],CharColor
          POP   BX

Continue2:
          INC   BX
          CMP   BX,(NumDispChars-1)*8*8
          JNG   Continue3
          XOR   BX,BX
          XOR   DX,DX
Continue3:
          LOOP  Loop2

          DEC   AX
          JNZ   Loop1

          INC   CurrentLine
          CMP   CurrentLine,(NumDispChars-1)*8
          JNG   Continue4
          MOV   CurrentLine,0

Continue4:
          INC   CurrentArrayLoc
          CMP   CurrentArrayLoc,73
          JNG   Continue5
          MOV   CurrentArrayLoc,0

Continue5:

      End;

    End;  { Cycle }


  Procedure SetInt9 ( I9Seg,I9Ofs : Word );

    Begin { SetInt9 }
      Asm
        PUSH    DS

        MOV     AH,35h
        MOV     AL,09h
        INT     21h
        MOV     Word Ptr Int9Vec,BX
        MOV     Word Ptr Int9Vec[2],ES

        MOV     AX,I9Seg
        MOV     DS,AX
        MOV     DX,I9Ofs
        MOV     AH,25h
        MOV     AL,09h
        INT     21h

        POP     DS
      End;
    End;  { SetInt9 }


  Procedure DisInt9;

    Begin { DisInt9 }
      Asm
        PUSH    DS
        MOV     DX,Word Ptr Int9Vec
        MOV     AX,Word Ptr Int9Vec[2]
        MOV     DS,AX
        MOV     AH,25h
        MOV     AL,09h
        INT     21h
        POP     DS
      End;
    End;  { DisInt9 }


  Procedure Int9;

  Interrupt;

    Begin { Int9 }
      Asm
        PUSHF
        CALL    Int9Vec
        INC     KeyHit
      End;
    End;  { Int9 }


  Procedure DrawString ( XPos,YPos,Size : Integer; Color : Byte; Str : String );

    Var TempPos,
        MemPos   : Word;
        XSize,
        YSize,
        Count,
        XCount,
        YCount : Integer;
        Letter : OneChar;

    Begin
      MemPos := (YPos-1)*320+(XPos-1);
      For Count := 1 To Length(Str) Do
        Begin
          Letter := CharSet[Ord(Str[Count])+1];
          For YCount := 1 To 8 Do
            For XCount := 1 To 8 Do
              If Letter[YCount] And ($80 Shr (XCount-1)) <> 0
                Then Begin
                  TempPos := MemPos+(YCount-1)*320*Size+(Count-1)*8*Size+(XCount-1)*Size;
                  For XSize := 1 To Size Do
                    For YSize := 1 To Size Do
                      Mem[VGA_Segment:TempPos+(XSize-1)+(YSize-1)*320] := Color;
                End;
        End;
    End;


  Var   Count,
        XCount : Integer;
        CurrAngle : Real;

  Begin { Cylinder_Scroll }

    SetInt9 (Seg(Int9),Ofs(Int9));
    KeyHit := False;

    Password := PW;
    VideoMode($13);
    GetChars;
    SetColor(CharColor,63,63,63);
    SetColor(4,63,0,0);
    SetColor(5,63,63,63);
    BuildCharArray;
    BuildPath;
    DrawString(64,150,1,4,'Loader by Fred Nietzche');
    DrawString(16,160,1,5,'Call CenterPoint! BBS (301) 309-0144');
    CurrentLine := 0;
    CurrentArrayLoc := 0;
    Repeat
      Cycle;
    Until KeyHit;
    VideoMode($3);

    DisInt9;

  End.  { Cylinder_Scroll }

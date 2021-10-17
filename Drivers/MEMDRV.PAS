{$IFDEF debug}
  {$A+,B-,D+,E+,F+,G+,I+,L+,N-,P+,Q+,R+,S+,V+,X+,Y+}
{$ELSE}
  {$A+,B-,D-,F+,E+,G+,I+,L-,N-,P+,Q-,R-,S-,V+,X+,Y-}
{$ENDIF}
unit MemDrv;

interface

uses
  Objects,
  Utils,
  Dos;

type
  PReferenceList = ^TReferenceList;
  PReference = ^TReference;
  TReferenceList = object(TList)
    function GetItem(index: integer): PReference;
    function IndexOf(item: PReference): integer;
    function Add(item: PReference): integer;
    procedure Insert(index: integer; item: PReference);
  end;
  TReference = record
    Size: longint;
    Ptr: pointer;
    Handle: word;
  end;
  PMemDrv = ^TMemDrv;
  TMemDrv = object(TObject)
  private
    _references: PReferenceList;
    _transactionIndex: integer;
    _currentReference: PReference;
    _memReserved: longint;
    _xmsEnabled: boolean;
    _xmsVersion: real;
    function GetXmsControltion: pointer; virtual;
    procedure XmsAlloc(reference: PReference; size: longint);
    procedure MoveReference(reference: PReference; var moveRecord); virtual;
    procedure MoveToConventional(reference: PReference); virtual;
  public
    Error: TError;
    constructor Create(reserved: longint);
    destructor Done; virtual;
    function XmsSupported: boolean;
    function XmsEnabled: boolean;
    function XmsMemAvailable: word;
    function XmsLargestBlock: word;
    function XmsVersion: real;
    function References: PReferenceList;
    procedure InitXms;
    procedure Init; virtual;
    procedure SetCurrentReference(reference: PReference); virtual;
    procedure Alloc(var reference: PReference; size: longint);
    procedure Dealloc(var reference: PReference); virtual;
    procedure BeginAllocTransaction; virtual;
    procedure CommitAllocTransaction; virtual;
    procedure RollbackAllocTransaction; virtual;
    procedure FreeReference(reference: PReference); virtual;
  end;


var
  Memory: TMemDrv;

implementation

const
  HiWord = 1;
  LoWord = 2;

type
  PXmsMoveRecord = ^TXmsMoveRecord;
  TXmsMoveRecord = record
    Length: longint;
    SourceHandle: word;
    SourceOffset: array[hiWord..loWord] of word;
    DestHandle: word;
    DestOffset: array[hiWord..loWord] of word;
  end;

var
  XmsControl: pointer;

function OnHeapError(size: word): integer; far;
begin
  OnHeapError := 1;
end;

constructor TMemDrv.Create(reserved: longint);
begin
    _memReserved := reserved;
  Init;
end;

function TMemDrv.References: PReferenceList;
begin
  References := _references;
end;

function TMemDrv.XmsEnabled: boolean;
begin
  XmsEnabled := _xmsEnabled;
end;

function TMemDrv.XmsSupported: boolean;
var
  reg: Registers;
  result: byte;
begin
  asm
    mov  ax, 4300h
    int  2Fh
    mov  [result], al
  end;
  XmsSupported := result = $80;
end;

procedure TMemDrv.InitXms;
var
  allocated: longint;
  size: longint;
  reference: PReference;
  version: word;
  revision: word;
  code: integer;
  hex: string;
begin
  ClearError(error);
  _xmsEnabled := false;
  if (XmsSupported) then
  begin
    XmsControl := GetXmsControltion;
    if (XmsControl = nil) then
    begin
      exit;
    end;
    asm
      push es
      mov  ah, 00h
      call [XmsControl]
      mov  [version], ax
      mov  [revision], bx
      pop  es
    end;
    _xmsEnabled := true;
    hex := Copy(IntToHex(revision),  3, 3);
    Val(hex, _xmsVersion, code);
    _xmsVersion := _xmsVersion / 100;
  end;
end;

function TMemDrv.GetXmsControltion: pointer;
var
  result: pointer;
begin
  asm
    push es
    mov  ax, 4310h
    int  2Fh
    mov  word ptr [result], bx
    mov  word ptr [result + 2], es
    pop  es
  end;
  GetXmsControltion := result;
end;

function TMemDrv.XmsMemAvailable: word;
var
  kbytes: word;
begin
  asm
    mov  ah, 08h
    call [XmsControl]
    mov  [kbytes], ax
  end;
  XmsMemAvailable := kbytes;
end;

function TMemDrv.XmsLargestBlock: word;
var
  kbytes: word;
begin
  asm
    mov  ah, 08h
    call [XmsControl]
    mov  [kbytes], dx
  end;
  XmsLargestBlock := kbytes;
end;

procedure TMemDrv.MoveReference(reference: PReference; var moveRecord);
var
  success: boolean;
  xmsError: byte;
  segm, offs: word;
  xseg: word;
begin
  ClearError(error);
  segm := Seg(moveRecord);
  offs := Ofs(moveRecord);
  xseg := Seg(XmsControl);
  asm
    push    ds
    mov     ah, 0bh
    mov     si, offs
    mov     bx, xseg
    mov     es, bx
    mov     bx, segm
    mov     ds, bx
    call    [ES:XmsControl]
    mov     byte ptr [success], al
    mov     byte ptr [xmsError], bl
    pop     ds
  end;
  if (not success) then
  begin
    CreateError(error, ecXmsError, esError);
  end;
end;

procedure TMemDrv.MoveToConventional(reference: PReference);
var
  xmsMoveRecord: TXmsMoveRecord;
  xmsHandle: word;
  xmsError: byte;
  index: integer;
  current: PReference;
  count: integer;
begin
  { If there is not enough conventional memory, purge references until there is }
  while (MaxAvail < reference^.Size) do
  begin
    if (_references^.Count = 0) then
    begin
      CreateError(error, ecNotEnoughMemory, esError);
      exit;
    end;
    index := 0;
    count := _references^.Count;
    while (index < count) and (MaxAvail < reference^.Size) do
    begin
      current := _references^.GetItem(index);
      if (current^.Ptr = nil) then
      begin
        Inc(index);
        continue;
      end;

      { if the reference hasn't existed in XMS previously, allocate the XMS for it }
      if (current^.Handle = 0) then
      begin
        XmsAlloc(current, current^.Size);
        if (xmsError = 1) then
        begin
          CreateError(error, ecNotEnoughMemory, esError);
          exit;
        end;
      end;
      with xmsMoveRecord do
      begin
        Length := current^.Size;
        SourceHandle := 0;
        SourceOffset[HiWord] := Ofs(current^.Ptr);
        SourceOffset[LoWord] := Seg(current^.Ptr);
        DestHandle := current^.Handle;
        DestOffset[HiWord] := 0;
        DestOffset[LoWord] := 0;
      end;
      MoveReference(current, xmsMoveRecord);
      FreeMem(current^.Ptr, current^.Size);
      current^.Ptr := nil;
      if (error.ErrorCode <> 0) then exit;
      Inc(index);
    end;
  end;

  { Allocate conventional memory for the reference }
  GetMem(reference^.Ptr, reference^.Size);

  { Move to conventional memory }
  with xmsMoveRecord do
  begin
    Length := reference^.Size;
    SourceHandle := reference^.Handle;
    SourceOffset[HiWord] := 0;
    SourceOffset[LoWord] := 0;
    DestHandle := 0;
    DestOffset[HiWord] := Ofs(reference^.Ptr);
    DestOffset[LoWord] := Seg(reference^.Ptr);
  end;
  MoveReference(reference, xmsMoveRecord);
  reference^.Handle := 0;
  _currentReference := reference;
end;

procedure TMemDrv.SetCurrentReference(reference: PReference);
begin
  ClearError(error);
  if (_currentReference = reference) then exit;
  if (reference^.Ptr <> nil) then exit;
  if (not XmsEnabled) then
  begin
    CreateError(error, ecInvalidMemoryReference, esError);
    exit;
  end;
  MoveToConventional(reference);
  if (error.ErrorCode <> ecNone) then
  begin
    exit;
  end;
  _currentReference := reference;
end;

procedure TMemDrv.XmsAlloc(reference: PReference; size: longint);
var
  xmsResult: word;
  xmsError: byte;
  xmsSize: word;
  xmsHandle: word;
begin
  xmsSize := Size div 1024;
  xmsHandle := 0;
  xmsResult := 0;
  xmsError := 0;
  if (Size mod 1024 > 0) then
    Inc(xmsSize, 1);
  asm
    push es
    push si
    mov  ah, 09h
    mov  dx, word ptr [xmsSize]
    call [XmsControl]
    mov  word ptr [xmsResult], ax
    mov  word ptr [xmsHandle], dx
    mov  byte ptr [xmsError], bl
    pop si
    pop es
  end;
  if (xmsError > 0) or (xmsResult = 0) then
  begin
    CreateError(error, ecNotEnoughMemory, esError);
    exit;
  end;
  reference^.Handle := xmsHandle;
end;

procedure TMemDrv.Alloc(var reference: PReference; size: longint);
begin
  ClearError(error);
  if (size = 0) then
  begin
    CreateError(error, ecInvalidAllocSize, esError);
    exit;
  end;
  reference := New(PReference);
  reference^.Size := Size;
  reference^.Ptr := nil;
  reference^.Handle := 0;
  if (size <= MaxAvail) then
  begin
    GetMem(reference^.Ptr, reference^.Size);
  end
  else if (XmsEnabled) then
  begin
    XmsAlloc(reference, reference^.Size);
  end
  else
  begin
    CreateError(error, ecNotEnoughMemory, esError);
    exit;
  end;
  _references^.Add(reference);
end;

procedure TMemDrv.FreeReference(reference: PReference);
var
  xmsResult: word;
  xmsError: byte;
  xmsHandle: word;
  index: integer;
begin
  ClearError(error);
  if (reference^.Handle > 0) then
  begin
    xmsHandle := reference^.Handle;
    asm
      mov  ah, 0Ah
      mov  dx, [xmsHandle]
      call [XmsControl]
      mov  bl, [xmsError]
    end;
    if (xmsError = 1) then
    begin
      CreateError(error, ecXmsError, esError);
    end;
  end
  else
  begin
    FreeMem(reference^.Ptr, reference^.Size);
  end;
  index := _references^.IndexOf(reference);
  if (index >= 0) then
    _references^.Delete(index);
end;

procedure TMemDrv.Dealloc(var reference: PReference);
var
  index: integer;
  current: PReference;
begin
  ClearError(error);
  if (reference^.Handle = 0) and (reference^.ptr = nil) then
  begin
    exit;
  end;
  reference^.Handle := 0;
  reference^.Ptr := nil;
  FreeReference(reference);
end;

function TMemDrv.XmsVersion: real;
begin
  XmsVersion := _xmsVersion;
end;

destructor TMemDrv.Done;
var
  index: integer;
  current: PReference;
begin
  if (_references^.Count > 0) then
  begin
    index := 0;
    while (_references^.Count > 0) do
    begin
      current := _references^.GetItem(index);
      if (current <> nil) then
      begin
        FreeReference(current);
      end;
      Inc(index);
    end;
  end;
  Dispose(_references, Done);
end;

procedure TMemDrv.BeginAllocTransaction;
begin
  _transactionIndex := _references^.Count;
end;

procedure TMemDrv.CommitAllocTransaction;
begin
  _transactionIndex := -1;
end;

procedure TMemDrv.RollbackAllocTransaction;
var
  index: integer;
  current: PReference;
begin
  ClearError(error);
  if (_transactionIndex < 0) or (_transactionIndex > _references^.Count - 1) then
    exit;
  for index := _references^.Count - 1 downTo _transactionIndex do
  begin
    current := _references^.GetItem(index);
    if (current <> nil) then
    begin
      FreeReference(current);
    end;
  end;
end;

procedure TMemDrv.Init;

begin
  _references := New(PReferenceList, Create('References'));
  _transactionIndex := -1;
  _currentReference := nil;
  _xmsVersion := 0;
  HeapError := @OnHeapError;
  XmsControl := nil;
  InitXms;
end;

function TReferenceList.GetItem(index: integer): PReference;
begin
  GetItem := TList.GetItem(index);
end;

function TReferenceList.IndexOf(item: PReference): integer;
begin
  IndexOf := TList.IndexOf(item);
end;

function TReferenceList.Add(item: PReference): integer;
begin
  Add := TList.Add(item);
end;

procedure TReferenceList.Insert(index: integer; item: PReference);
begin
  TList.Insert(index, item);
end;

begin
end.
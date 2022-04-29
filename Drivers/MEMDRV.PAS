{$I Compiler.inc}
unit MemDrv;

interface

uses
  Objects,
  Utils,
  TPAlloc,
  Collects,
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
  TReferenceType =
  (
    Conventional,
    Xms
  );
  TReference = record
    Xms: boolean;
    Size: longint;
    Offset: longint;
  end;
  TLowerPointer = record
    Reference: PReference;
    Offset: word;
  end;
  PMemDrv = ^TMemDrv;
  TMemDrv = object(TObject)
  private
    _references: PReferenceList;
    _currentReference: PReference;
    _memReserved: longint;
    _xmsEnabled: boolean;
    _xmsVersion: real;
    _xmsHandle: word;
    _xmsLowerMemorySize: longint;
    _buffer: PByte;
    _bufferSize: longint;
    _lowerAllocated: longint;
    _xmsAllocated: longint;
    _xmsSize: longint;
    _transactionReferences: PReferenceList;
    function GetXmsControlFunction: pointer; virtual;
    function GetNextOffset(size: longint; xms: boolean): longint; virtual;
    function XmsAlloc(size: longint): word; virtual;
    function MaxAvail(xms: boolean): longint; virtual;
    procedure MoveReference(reference: PReference; var moveRecord); virtual;
    procedure MoveToConventional(reference: PReference); virtual;
  public
    Error: TError;
    constructor Create(reserved: longint);
    destructor Done; virtual;
    function XmsSupported: boolean;
    function XmsEnabled: boolean; virtual;
    function XmsMemAvail: longint; virtual;
    function XmsMaxAvail: longint; virtual;
    function LowerMaxAvail: longint; virtual;
    function LowerMemAvail: longint; virtual;
    function XmsVersion: real;
    function References: PReferenceList;
    function BufferSize: longint;
    function CurrentReference: PReference;
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

function ReferenceOffsetCompare(item1, item2: pointer): integer; far;
var
  ref1, ref2: TReference;
  result: integer;
begin
  ref1 := PReference(item1)^;
  ref2 := PReference(item2)^;
  result := 0;
  if (ref1.Offset < ref2.Offset) then
    result := -1
  else if (ref1.Offset > ref2.Offset) then
    result := 1;
  ReferenceOffsetCompare := result;
end;

function OnHeapError(size: word): integer; far;
begin
  OnHeapError := 1;
end;

function IsXms(item: pointer; var value): boolean; far;
begin
  IsXms   := PReference(item)^.Xms = boolean(value);
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

function TMemDrv.BufferSize: longint;
begin
  BufferSize := _bufferSize;
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
  version: word;
  revision: word;
  code: integer;
  hex: string;
  xmsHandle: word;
  xmsError: byte;
  xmsAllocated: word;
  size: word;
  kbytes: word;
  {$IFDEF debug}
    filename: string;
    debugFile: File;
  {$ENDIF}
begin
  _xmsEnabled := false;
  if (XmsSupported) then
  begin
    XmsControl := GetXmsControlFunction;
    if (XmsControl = nil) then
    begin
      exit;
    end;
    asm
      { Initialize XMS }
      push es
      mov  ah, 00h
      call [XmsControl]
      mov  [version], ax
      mov  [revision], bx
      pop  es
      { Get max XMS available }
      mov  ah, 08h
      call [XmsControl]
      mov  [kbytes], dx
    end;
    size := kbytes;
    asm
      mov  ah, 09h
      mov  dx, [size]
      call [xmsControl]
      mov  [xmsHandle], dx
      mov  [xmsAllocated], ax
      mov  [xmsError], bl
    end;
    _xmsSize := longint(size) * 1024;
    if (xmsError > 0) or (xmsAllocated = 0) then exit;
    _xmsHandle := xmsHandle;
    _xmsEnabled := true;
    hex := Copy(IntToHex(revision),  3, 3);
    Val(hex, _xmsVersion, code);
    _xmsVersion := _xmsVersion / 100;
    {$IFDEF debug}
      filename := 'XmsDebug.bin';
      Assign(debugFile, filename);
      Rewrite(debugFile, 1);
      BlockWrite(debugFile, _xmsHandle, SizeOf(_xmsHandle));
      Close(debugFile);
    {$ENDIF}
  end;
end;

function TMemDrv.GetNextOffset(size: longint; xms: boolean): longint;
var
  index: integer;
  offset: longint;
  reference: PReference;
  filtered: PList;
  count: integer;
begin
  offset := 0;
  GetNextOffset := 0;
  filtered := _references^.Where(IsXms, xms);
  if (filtered^.Count = 0) then exit;
  count := filtered^.Count;
  for index := 0 to count - 1 do
  begin
    reference := filtered^.GetItem(index);
    if (xms and not reference^.Xms) or ((not xms) and reference^.Xms) then
      continue;
    if (offset + size < reference^.Offset) then break;
    Inc(offset, reference^.Size);
  end;
  Dispose(filtered, Done);
  GetNextOffset := offset;
end;

function TMemDrv.GetXmsControlFunction: pointer;
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
  GetXmsControlFunction := result;
end;

function TMemDrv.CurrentReference: PReference;
begin
  CurrentReference := _currentReference;
end;

procedure TMemDrv.MoveReference(reference: PReference; var moveRecord);
var
  success: boolean;
  xmsError: byte;
  segm, offs: word;
  xseg: word;
begin
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
  offset: longint;
  dest: longint;
begin
  { If there is not enough conventional memory, purge references until there is }
  while (LowerMaxAvail < reference^.Size) do
  begin
    if (_references^.Count = 0) then
    begin
      CreateError(error, ecNotEnoughMemory, esError);
      exit;
    end;
    index := 0;
    count := _references^.Count;
    while (index < count) and (LowerMaxAvail < reference^.Size) do
    begin
      current := _references^.GetItem(index);
      if (not current^.Xms) then
      begin
        Inc(index);
        continue;
      end;
      with xmsMoveRecord do
      begin
        Length := current^.Size;
        SourceHandle := 0;
        SourceOffset[HiWord] := Ofs(current^.Offset);
        SourceOffset[LoWord] := Seg(current^.Offset);
        DestHandle := _xmsHandle;
        offset := GetNextOffset(current^.Size, true);
        DestOffset[HiWord] := Ofs(offset);
        DestOffset[LoWord] := Seg(offset);
      end;
      MoveReference(current, xmsMoveRecord);
      Dec(_lowerAllocated, current^.Size);
      reference^.Xms := true;
      current^.Offset := 0;
      if (error.ErrorCode <> 0) then exit;
      Inc(index);
    end;
  end;

  { Allocate conventional memory for the reference }
  dest := GetNextOffset(reference^.Size, false);
  Inc(_lowerAllocated, reference^.Size);

  { Move to conventional memory }
  with xmsMoveRecord do
  begin
    Length := reference^.Size;
    SourceHandle := _xmsHandle;
    SourceOffset[HiWord] := Ofs(reference^.Offset);
    SourceOffset[LoWord] := Seg(reference^.Offset);
    DestHandle := 0;
    DestOffset[HiWord] := Ofs(dest);
    DestOffset[LoWord] := Seg(dest);
  end;
  MoveReference(reference, xmsMoveRecord);
  Dec(_xmsAllocated, reference^.Size);
  reference^.Offset := dest;
  reference^.Xms := false;
  _currentReference := reference;
end;

function TMemDrv.MaxAvail(Xms: boolean): longint;
var
  index: integer;
  result: longint;
  reference: PReference;
  next: PReference;
  avail: longint;
  count: integer;
  offset: longint;
  size: longint;
  blockSize: longint;
  filtered: PList;
begin
  result := 0;
  if (xms) then avail := _xmsSize else avail := _bufferSize;
  { get only references with Xms flag that matches the Xms parameter }
  filtered := _references^.Where(IsXms, Xms);
  if (filtered^.Count = 0) then
  begin
    MaxAvail := avail;
    exit;
  end;
  if (filtered^.Count = 1) then
  begin
    reference := PReference(filtered^.GetItem(0));
    MaxAvail := avail - reference^.Size;
    exit;
  end;
  for index := 0 to filtered^.Count - 1 do
  begin
    reference := filtered^.GetItem(index);
    offset := reference^.Offset;
    size := reference^.Size;
    { get the size between current reference and next }
    if (index + 1 < filtered^.Count - 1) then
    begin
      next := filtered^.GetItem(index + 1);
      blockSize := next^.Offset - (offset + size);
    end
    { no reference atfer the current, so return size between reference and max }
    else
    begin
      blockSize := avail - (offset + size);
    end;
    if (size > result) then
      result := size;
  end;
  dispose(filtered, done);
  MaxAvail := result;
end;

function TMemDrv.LowerMaxAvail: longint;
begin
  LowerMaxAvail := MaxAvail(false);
end;

function TMemDrv.LowerMemAvail: longint;
begin
  LowerMemAvail := _bufferSize - _lowerAllocated;
end;

function TMemDrv.XmsMemAvail: longint;
begin
  XmsMemAvail := _xmsSize - _xmsAllocated;
end;

function TMemDrv.XmsMaxAvail: longint;
begin
  XmsMaxAvail := MaxAvail(true);
end;

procedure TMemDrv.SetCurrentReference(reference: PReference);
begin
  if (_currentReference = reference) then exit;
  _currentReference := reference;
  if (not reference^.Xms) then exit;
  MoveToConventional(reference);
  if (error.ErrorCode <> ecNone) then
  begin
    exit;
  end;
end;

function TMemDrv.XmsAlloc(size: longint): word;
var
  xmsResult: word;
  xmsError: byte;
  xmsSize: word;
  xmsHandle: word;
begin
  XmsAlloc := 0;
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
  XmsAlloc := xmsHandle;
end;

procedure TMemDrv.Alloc(var reference: PReference; size: longint);
var
  lowAvail: longint;
  xmsAvail: longint;
begin
  if (size = 0) then
  begin
    CreateError(error, ecInvalidAllocSize, esError);
    exit;
  end;
  reference := New(PReference);
  reference^.Size := Size;
  reference^.Offset := 0;
  lowAvail := LowerMaxAvail;
  xmsAvail := XmsMaxAvail;
  if (size <= lowAvail) then
  begin
    reference^.Offset := GetNextOffset(size, false);
    reference^.Size := size;
    Inc(_lowerAllocated, size);
    reference^.Xms := false;
  end
  else if (XmsEnabled) and (size <= xmsAvail) then
  begin
    reference^.Offset := GetNextOffset(size, true);
    reference^.Size := size;
    Inc(_xmsAllocated, size);
    reference^.Xms := true;
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
  index := _references^.IndexOf(reference);
  if (not reference^.Xms) then
    Dec(_lowerAllocated, reference^.Size)
  else
    Dec(_xmsAllocated, reference^.Size);
  if (index >= 0) then
    _references^.Delete(index);
end;

procedure TMemDrv.Dealloc(var reference: PReference);
var
  index: integer;
  current: PReference;
begin
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
  xmsHandle: word;
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
  index := 0;
  HugeFreeMem(_buffer, _bufferSize);
  xmsHandle := _xmsHandle;
  if (XmsEnabled) then
  asm
    mov  ah, 0Ah
    mov  dx, [xmsHandle]
    call [XmsControl]
  end;
end;

procedure TMemDrv.BeginAllocTransaction;
begin
  _transactionReferences := New(PReferenceList, Create);
end;

procedure TMemDrv.CommitAllocTransaction;
begin
  Dispose(_transactionReferences, Done);
  _transactionReferences := nil;
end;

procedure TMemDrv.RollbackAllocTransaction;
var
  index: integer;
  current: PReference;
begin
  if (_transactionReferences <> nil) then
    exit;
  index := _transactionReferences^.Count - 1;
  while (index >= 0) do
  begin
    current := _references^.GetItem(index);
    FreeReference(current);
    Dec(index);
  end;
  Dispose(_transactionReferences, Done);
end;

procedure TMemDrv.Init;
var
  reference: PReference;
  size: word;
begin
  ClearError(error);
  { references are always sorted by Xms flag and Offset ascending }
  _references := New(PReferenceList, CreateSorted('References', ReferenceOffsetCompare));
  _currentReference := nil;
  _xmsVersion := 0;
  _xmsHandle := 0;
  _buffer := nil;
  _bufferSize := 0;
  _lowerAllocated := 0;
  _xmsAllocated := 0;
  reference := nil;
  _bufferSize := System.MaxAvail - _memReserved;
  _xmsSize := 0;
  _transactionReferences := nil;
  HugeGetMem(_buffer, _bufferSize);
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
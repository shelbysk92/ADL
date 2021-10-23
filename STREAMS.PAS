{$I Compiler.inc}
unit Streams;

interface

uses
  Dos,
  Objects,
  Utils,
  TPAlloc,
  MemDrv;

type
  TSeekOrigin =
  (
    soBeginning,
    soEnd
  );
  TStreamStatus =
  (
    ssOk,
    ssError,
    ssEndOfStream
  );
  PStream = ^TStream;
  TStream = object(TObject)
  private
    _position: longint;
    _error: TError;
    _status: TStreamStatus;
    _length: longint;
    _canRead, _canWrite, _canSeek: boolean;
    _closed: boolean;
    _buffers: PReferenceList;
    _currentBuffer: integer;
    _currentBufferPos: integer;
  public
    constructor Create;
    destructor Done; virtual;
    function Position: longint; virtual;
    function Length: longint; virtual;
    function Status: TStreamStatus; virtual;
    function EndOfStream: boolean; virtual;
    function CanRead: boolean; virtual;
    function CanWrite: boolean; virtual;
    function CanSeek: boolean; virtual;
    function Read(var buffer; count: longint): longint; virtual;
    function Write(var buffer; count: longint): longint; virtual;
    function Seek(offset: longint; origin: TSeekOrigin): longint; virtual;
    function ReadByte: byte; virtual;
    function WriteToStream(stream: TStream; count: longint): longint; virtual;
    function ReadFromStream(stream: TStream; count: longint): longint; virtual;
    procedure Init; virtual;
    procedure GetLastError(var error: TError); virtual;
    procedure Close; virtual;
    procedure Flush; virtual;
    procedure SetLength(newLength: longint); virtual;
    procedure WriteByte; virtual;
  end;
  PMemoryStream = ^TMemoryStream;
  TMemoryStream = object(TStream)
  private
  public
    constructor Create(size: longint; var error: TError);
    destructor Done; virtual;
    function Read(var readBuffer; count: longint): longint; virtual;
    function Write(var writeBuffer; count: longint): longint; virtual;
    function Seek(offset: longint; origin: TSeekOrigin): longint; virtual;
    function ReadByte: byte; virtual;
    function WriteToStream(stream: TStream; count: longint): longint; virtual;
    function ReadFromStream(stream: TStream; count: longint): longint; virtual;
    function  Buffer: pointer;
    procedure Init; virtual;
    procedure SetLength(newLength: longint); virtual;
    procedure WriteByte; virtual;
  end;

implementation

const
  MaxAlloc = 65528;

constructor TStream.Create;
begin
  Init;
end;

destructor TStream.Done;
begin
  Close;
end;

function TStream.Position: longint;
begin
  Position := _position;
end;

function TStream.Length: longint;
begin
  Length := _length;
end;

function TStream.Status: TStreamStatus;
begin
  Status := status;
end;

function TStream.EndOfStream: boolean;
begin
  EndOfStream := _position > _length;
end;

function TStream.CanRead: boolean;
begin
  CanRead := _canRead;
end;

function TStream.CanWrite: boolean;
begin
  CanWrite := _canWrite;
end;

function TStream.CanSeek: boolean;
begin
  CanSeek := _canSeek;
end;

function TStream.Read(var buffer; count: longint): longint;
begin
end;

function TStream.Write(var buffer; count: longint): longint;
begin
end;

function TStream.Seek(offset: longint; origin: TSeekOrigin): longint;
begin
end;

function TStream.ReadByte: byte;
begin
end;

function TStream.WriteToStream(stream: TStream; count: longint): longint;
begin
end;

function TStream.ReadFromStream(stream: TStream; count: longint): longint;
begin
end;

procedure TStream.Init;
begin
  _position := -1;
  ClearError(_error);
  _status := ssEndOfStream;
  _length := 0;
  _canRead := false;
  _canWrite := false;
  _canSeek := false;
  _closed := true;
end;

procedure TStream.GetLastError(var error: TError);
begin
  error := _error;
end;

procedure TStream.Close;
begin
  Flush;
  _closed := true;
end;

procedure TStream.Flush;
begin
end;

procedure TStream.SetLength(newLength: longint);
begin
end;

procedure TStream.WriteByte;
begin
end;

constructor TMemoryStream.Create(size: longint; var error: TError);
var
  index: integer;
  reference: PReference;
  allocated: longint;
  maxAllocSize: longint;
  newSize: longint;
begin
  _position := 0;
  ClearError(_error);
  _status := ssOk;
  _canRead := true;
  _canWrite := true;
  _canSeek := true;
  _closed := false;
  _length := size;
  _buffers := New(PReferenceList, Create('Buffers'));
  Memory.BeginAllocTransaction;

  allocated := 0;
  while (allocated < size) do
  begin
    newSize := MinL(MaxAlloc, size - allocated);
    Memory.Alloc(reference, newSize);
    if (Memory.Error.ErrorCode <> ecNone) then
    begin
      error := Memory.Error;
      ClearError(Memory.Error);
      Memory.RollbackAllocTransaction;
      exit;
    end;
    _buffers^.Add(reference);
    Inc(allocated, newSize);
  end;
  Memory.CommitAllocTransaction;
end;

destructor TMemoryStream.Done;
var
  index: integer;
begin
  index := 0;
  while (index < _buffers^.Count) do
  begin
    Memory.FreeReference(_buffers^.GetItem(index));
    Inc(index);
  end;
  Dispose(_buffers, Done);
end;

function TMemoryStream.Read(var readBuffer; count: longint): longint;
begin
end;

function TMemoryStream.Write(var writeBuffer; count: longint): longint;
begin

end;

function TMemoryStream.Seek(offset: longint; origin: TSeekOrigin): longint;
begin
end;

function TMemoryStream.ReadByte: byte;
begin
end;

function TMemoryStream.WriteToStream(stream: TStream; count: longint): longint;
begin
end;

function TMemoryStream.ReadFromStream(stream: TStream; count: longint): longint;
begin
end;

function TMemoryStream.Buffer: pointer;
var
  bufferPos: longint;
  bufferIndex: integer;
begin
  Buffer := nil;
  if (_buffers^.Count = 0) then exit;
  bufferIndex := _position div MaxAlloc;
  bufferPos := _position mod MaxAlloc;
  if (Memory.CurrentReference <> _buffers^.GetItem(bufferIndex)) then
    Memory.SetCurrentReference(_buffers^.GetItem(bufferIndex));
  Buffer := LinearToPointer(Memory.CurrentReference^.Offset + bufferPos);
end;

procedure TMemoryStream.Init;
begin
  TStream.Init;
  TypeName := 'TMemoryStream';
end;

procedure TMemoryStream.SetLength(newLength: longint);
begin
end;

procedure TMemoryStream.WriteByte;
begin
end;

begin
end.
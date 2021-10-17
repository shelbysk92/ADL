unit Streams;

interface

uses
  Dos,
  Objects,
  Utils,
  MemDrv;

const
  MaxAllocSize: word = 65528;

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
  TStream = object(TBaseObject)
  private
    _position: longint;
    _error: TError;
    _status: TStreamStatus;
    _length: longint;
    _canRead, _canWrite, _canSeek: boolean;
    _closed: boolean;
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
    _buffers: PReferenceList;
  public
    constructor Create(size: longint);
    destructor Done; virtual;
    function Read(var buffer; count: longint): longint; virtual;
    function Write(var buffer; count: longint): longint; virtual;
    function Seek(offset: longint; origin: TSeekOrigin): longint; virtual;
    function ReadByte: byte; virtual;
    function WriteToStream(stream: TStream; count: longint): longint; virtual;
    function ReadFromStream(stream: TStream; count: longint): longint; virtual;
    function Buffers: PReferenceList;
    procedure Init; virtual;
    procedure SetLength(newLength: longint); virtual;
    procedure WriteByte; virtual;
  end;

implementation

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

constructor TMemoryStream.Create(size: longint);
var
  index: integer;
  totalBytes: longint;
  newSize: longint;
  reference: PReference;
begin
  _position := 0;
  ClearError(_error);
  _status := ssOk;
  _canRead := true;
  _canWrite := true;
  _canSeek := true;
  _closed := false;
  _buffers := New(PReferenceList, Create('_buffers'));
  _length := size;
  totalBytes := 0;
  Memory.BeginAllocTransaction;
  while totalBytes < size do
  begin
    newSize := MinL(size - totalBytes, MaxAllocSize);
    if (newSize mod 2) <> 0 then
      Inc(newSize, 1);
    Memory.Alloc(reference, newSize);
    _buffers^.Add(reference);
    if (_error.ErrorCode <> 0) then
    begin
      Memory.RollbackAllocTransaction;
      exit;
    end;
    Inc(totalBytes, newSize);
  end;
  Memory.CommitAllocTransaction;
end;

destructor TMemoryStream.Done;
var
  index: integer;
begin
  for index := 0 to _buffers^.Count - 1 do
  begin
    Memory.FreeReference(_buffers^.GetItem(index));
  end;
  Dispose(_buffers, Done);
end;

function TMemoryStream.Read(var buffer; count: longint): longint;
begin
end;

function TMemoryStream.Write(var buffer; count: longint): longint;
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

procedure TMemoryStream.Init;
begin
end;

procedure TMemoryStream.SetLength(newLength: longint);
begin
end;

procedure TMemoryStream.WriteByte;
begin
end;

function TMemoryStream.Buffers: PReferenceList;
begin
  Buffers := _buffers;
end;

begin
end.
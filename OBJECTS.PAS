{$IFDEF debug}
  {$A+,B-,D+,F+,G+,I+,L+,N+,P+,Q+,R+,S+,V+,X+,Y+}
{$ELSE}
  {$A+,B-,D-,F+,G+,I+,L-,N+,P+,Q-,R-,S-,V+,X+,Y-}
{$ENDIF}
unit Objects;

interface

uses
  Consts,
  Utils;

type
  PByte = ^Byte;
  PBaseObject = ^TBaseObject;
  TBaseObject = object
  private
  public
    constructor Create;
    procedure Init; virtual;
    destructor Done; virtual;
  end;
  PObject = ^TObject;
  TObject = object(TBaseObject)
  private
  public
    TypeName: string25;
    Id: string25;
    constructor Create(newId: string);
    procedure Init; virtual;
    function ToString: string; virtual;
  end;
  PList = ^TList;
  TList = object(TObject)
  private
    _buffer: pointer;
    _count: integer;
    _capacity: integer;
  public
    constructor CreateCapacity(newId: string; initialCapacity: integer);
    constructor Create(newId: string);
    procedure Init; virtual;
    destructor Done; virtual;
    function ToString: string; virtual;
    function GetItem(index: integer): pointer;
    function IndexOf(item: pointer): integer;
    function Add(item: pointer): integer;
    function Count: integer;
    function Capacity: integer;
    procedure SetCapacity(cap: integer);
    procedure Insert(index: integer; item: pointer);
    procedure Delete(index: integer);
    procedure Clear; virtual;
  end;
  PObjectList = ^TObjectList;
  TObjectList = object(TList)
  private
  public
    DisposeObjects: boolean;
    destructor Done; virtual;
    procedure Init; virtual;
    function ToString: string; virtual;
    function GetItem(index: integer): PObject;
    function IndexOf(item: PObject): integer;
    function IndexOfId(idToFind: string25): integer;
    function Add(item: PObject): integer;
    procedure Insert(index: integer; item: PObject);
    procedure Delete(index: integer);
    procedure Clear; virtual;
  end;
  PAllocationError = ^TAllocationError;
  TAllocationError = procedure(var error: TError);
  PPersistent = ^TPersistent;
  TPersistent = object(TObject)
  public
    procedure Assign(source: TPersistent); virtual;
    procedure AssignTo(dest: TPersistent); virtual;
  end;

var
  OnAllocationError: PAllocationError;

implementation

uses
  Crt;

type
  PPointer = ^Pointer;

constructor TBaseObject.Create;
begin
  Init;
end;

procedure TBaseObject.Init;
begin
end;

destructor TBaseObject.Done;
begin
end;

constructor TObject.Create(newId: string);
begin
  Id := NewId;
  Init;
end;

procedure TObject.Init;
begin
  TBaseObject.Init;
  TypeName := 'TObject';
end;

function TObject.ToString: string;
begin
  ToString := TypeName;
end;

constructor TList.CreateCapacity(newId: string; initialCapacity: integer);
begin
  Id := newId;
  _capacity := 0;
  SetCapacity(initialCapacity);
  Init;
end;

constructor TList.Create(newId: string);
begin
  Id := newId;
  _capacity := 0;
  SetCapacity(DefaultListCapacity);
  Init;
end;

procedure TList.Init;
begin
  TObject.Init;
  TypeName := 'TList';
  _count := 0;
end;

destructor TList.Done;
begin
  if (_buffer <> nil) then FreeMem(_buffer, _capacity * SizeOf(Pointer));
  TObject.Done;
end;

function TList.ToString: string;
begin
  ToString := 'TList';
end;

function TList.GetItem(index: integer): pointer;
var
  itemLoc: pointer;
  result: pointer;
begin
  if (index < 0) or (index > _count) then
  begin
    GetItem := nil;
    Exit;
  end;
  itemLoc := Pointer(LongInt(_buffer) + 4 * index);
  Move(itemLoc^, result, 4);
  GetItem := result;
end;

function TList.IndexOf(item: pointer): integer;
var
  index: integer;
  current: pointer;
  itemLoc: PPointer;
begin
  IndexOf := -1;
  if (_count = 0) then
    Exit;
  index := 0;
  repeat
    if (index > _count) then
      break;
    itemLoc := pointer(LongInt(_buffer) + 4 * index);
    current := itemLoc^;
    if (item = current) then
    begin
      IndexOf := index;
      break;
    end;
    Inc(index);
  until false;
end;

function TList.Add(item: pointer): integer;
var
  newCap: word;
  itemLoc: PPointer;
begin
  if (_count + 1 > _capacity) then
  begin
    newCap := _capacity * 2;
    SetCapacity(newCap);
  end;
  itemLoc := pointer(LongInt(_buffer) + 4 * _count);
  Inc(_count);
  itemLoc^ := item;
end;

procedure TList.Insert(index: integer; item: pointer);
var
  newCap: integer;
  itemLoc: PPointer;
  locIndex: integer;
begin
  if (_count + 1 > _capacity) then
  begin
    newCap := _capacity * 2;
    SetCapacity(newCap);
  end;
  for locIndex := _count - 1 downto index do
  begin
    itemLoc := pointer(LongInt(_buffer) + locIndex * 4);
    Move(itemLoc^, pointer(LongInt(itemLoc) + 4)^, 4);
  end;
  Inc(_count);
  itemLoc^ := item;
end;

procedure TList.Delete(index: integer);
var
  newCap: LongInt;
  itemLoc: pointer;
  locIndex: LongInt;
begin
  for locIndex := index to _count - 1  do
  begin
    itemLoc := pointer(LongInt(_buffer) + locIndex * 4);
    Move(pointer(LongInt(itemLoc) + 4)^, itemLoc^, 4);
  end;
  Dec(_count);
end;

procedure TList.Clear;
begin
  FreeMem(_buffer, _capacity *  SizeOf(pointer));
  _count := 0;
  _buffer := nil;
  _capacity := 0;
  SetCapacity(DefaultListCapacity);
end;

procedure TList.SetCapacity(cap: integer);
var
  newBuffer: pointer;
  max: word;
  dataSize: word;
  error: TError;
begin
  if (_capacity = cap) then exit;
  dataSize := cap * SizeOf(Pointer);
  GetMem(newBuffer, dataSize);
  if (newBuffer = nil) then
  begin
    if (OnAllocationError <> nil) then
      TAllocationError(OnAllocationError^)(error);
    exit;
  end;
  FillChar(newBuffer^, dataSize, 0);
  if (_capacity > 0) and (_buffer <> nil) then
  begin
    if (cap > _capacity) then
      Move(_buffer^, newBuffer^, _capacity)
    else
      Move(_buffer^, NewBuffer^, cap);
    FreeMem(_buffer, _capacity * SizeOf(pointer));
  end;
  _buffer := newBuffer;
  _capacity := cap;
  if _count > _capacity then
    _count := _capacity;
end;

function TList.Count: integer;
begin
  Count := _count;
end;

function TList.Capacity: integer;
begin
  Capacity := _capacity;
end;

procedure TObjectList.Init;
begin
  TList.Init;
  TypeName := 'TObjectList';
  DisposeObjects := true;
end;

destructor TObjectList.Done;
var
  index: integer;
  item: PObject;
begin;
  if DisposeObjects then
  begin
    for index := 0 to _count - 1 do
    begin;
      item := GetItem(index);
      Dispose(item, Done);
    end;
  end;
  TList.Done;
end;

function TObjectList.ToString: string;
begin
  ToString := 'TObjectList';
end;

function TObjectList.GetItem(index: integer): PObject;
begin
  GetItem := TList.GetItem(index);
end;

function TObjectList.IndexOf(item: PObject): integer;
begin
  IndexOf := TList.IndexOf(item);
end;

function TObjectList.IndexOfId(idToFind: string25): integer;
var
  index: integer;
  currentId: string25;
begin
  IndexOfId := -1;
  for index := 0 to _count - 1 do
  begin
    currentId := GetItem(index)^.Id;
    if (currentId = idToFind) then
    begin
      IndexOfId := index;
      break;
    end;
  end;
end;

function TObjectList.Add(item: PObject): integer;
begin
  Add := TList.Add(item);
end;

procedure TObjectList.Insert(index: integer; item: PObject);
begin
  TList.Insert(index, item);
end;

procedure TObjectList.Delete(index: integer);
var
  obj: PObject;
begin
  obj := GetItem(index);
  Dispose(obj);
end;

procedure TObjectList.Clear;
var
  index: word;
  item: PObject;
begin
  TList.Clear;
end;

procedure TPersistent.Assign(source: TPersistent);
begin
end;

procedure TPersistent.AssignTo(dest: TPersistent);
begin
end;

begin
  OnAllocationError := nil;

end.
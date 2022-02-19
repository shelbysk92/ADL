unit Collects;

interface

uses
  Consts,
  Utils,
  Objects;

type

  TCollection = object(TObject)
  private
    _buffer: pointer;
    _count: integer;
    _capacity: integer;
  public
    { Constructors/Destructors and Initialization }
    constructor CreateCapacity(newId: string; initialCapacity: integer);
    constructor Create(newId: string);
    destructor Done; virtual;
    procedure Init; virtual;

    { Properties }
    function Count: integer; virtual;
    function Capacity: integer; virtual;

    { Modification Functions }
    function Add(item: pointer): integer;
    procedure Delete(index: integer);
    procedure Clear; virtual;

    { Misc Functions }
    function ToString: string; virtual;
    procedure SetCapacity(cap: integer);
  end;
  PList = ^TList;
  TList = object(TCollection)
  private
    _sorted: boolean;
    _comparer: TComparer;
  public
    { Constructors/Destructors and Initialization }
    constructor CreateSorted(newId: string; comparer: TComparer);
    procedure Init; virtual;

    { Modification Functions }
    function Add(item: pointer): integer;

    { Sorting Functions }
    function GetSortedIndex(item: pointer): integer; virtual;
    procedure Sort(comparer: TComparer); virtual;
    function Sorted: boolean; virtual;

    { Index-Based Functions }
    function GetItem(index: integer): pointer;
    procedure SetItem(index: integer; item: pointer);
    function IndexOf(item: pointer): integer;
    procedure Insert(index: integer; item: pointer);

    { Misc Functions }
    function ToString: string; virtual;
    function Where(predicate: TPredicate; var value): PList;
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
  PStack = ^TStack;
  TStack = object(TObjectList)
  private
  public
    procedure Init; virtual;
    function Push(obj: PObject): integer;
    function Pop: PObject;
  end;

implementation

constructor TCollection.CreateCapacity(newId: string; initialCapacity: integer);
begin
  Id := newId;
  _capacity := 0;
  SetCapacity(initialCapacity);
  Init;
end;

constructor TCollection.Create(newId: string);
begin
  Id := newId;
  _capacity := 0;
  SetCapacity(DefaultListCapacity);
  Init;
end;

procedure TCollection.Init;
begin
  TObject.Init;
  TypeName := 'TList';
  _count := 0;
end;

destructor TCollection.Done;
begin
  if (_buffer <> nil) then FreeMem(_buffer, _capacity * SizeOf(Pointer));
  TObject.Done;
end;

procedure TCollection.SetCapacity(cap: integer);
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
      Move(_buffer^, newBuffer^, _capacity * SizeOf(pointer))
    else
      Move(_buffer^, NewBuffer^, cap * SizeOf(pointer));
    FreeMem(_buffer, _capacity * SizeOf(pointer));
  end;
  _buffer := newBuffer;
  _capacity := cap;
  if _count > _capacity then
    _count := _capacity;
end;

function TCollection.Count: integer;
begin
  Count := _count;
end;

function TCollection.Capacity: integer;
begin
  Capacity := _capacity;
end;

function TCollection.Add(item: pointer): integer;
var
  newCap: word;
  itemLoc: PPointer;
  index: integer;
begin
  if (_count + 1 > _capacity) then
  begin
    newCap := _capacity * 2;
    SetCapacity(newCap);
  end;
  index := _count;
  itemLoc := pointer(LongInt(_buffer) + 4 * index);
  Inc(_count);
  itemLoc^ := item;
end;

procedure TCollection.Delete(index: integer);
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

procedure TCollection.Clear;
begin
  FreeMem(_buffer, _capacity *  SizeOf(pointer));
  _count := 0;
  _buffer := nil;
  _capacity := 0;
  SetCapacity(DefaultListCapacity);
end;

function TCollection.ToString: string;
begin
  ToString := 'TCollection';
end;

constructor TList.CreateSorted(newId: string; comparer: TComparer);
begin
  Id := newId;
  _capacity := 0;
  _comparer := comparer;
  SetCapacity(DefaultListCapacity);
  Init;
  _sorted := true;
end;

procedure TList.Init;
begin
  TCollection.Init;
  TypeName := 'TList';
  _sorted := false;
end;

function TList.Sorted: boolean;
begin
  Sorted := _sorted;
end;

function TList.ToString: string;
begin
  ToString := 'TList';
end;

procedure TList.SetItem(index: integer; item: pointer);
var
  itemLoc: pointer;
begin
  itemLoc := Pointer(LongInt(_buffer) + 4 * index);
  Move(itemLoc^, item, 4);
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

function TList.Add(item: pointer): integer;
var
  newCap: word;
  itemLoc: PPointer;
  index: integer;
begin
  if (_count + 1 > _capacity) then
  begin
    newCap := _capacity * 2;
    SetCapacity(newCap);
  end;
  index := _count;
  if (_sorted) then
  begin
    index := GetSortedIndex(item);
  end;
  if (index = _count) then
  begin
    itemLoc := pointer(LongInt(_buffer) + 4 * index);
    Inc(_count);
    itemLoc^ := item;
  end
  else
    Insert(index, item);
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

procedure TList.Sort(comparer: TComparer);
  procedure QuickSort(lowIndex, highIndex: integer);
  var
    low, high: integer;
    pivot, temp, lowItem, highItem: pointer;
  begin
    low := lowIndex;
    high := highIndex;
    lowItem := GetItem(lowIndex);
    highItem := GetItem(highIndex);
    pivot := GetItem((lowIndex + highIndex) div 2);
    repeat
      while comparer(lowItem, pivot) < 0 do
        Inc(low) ;
      while comparer(highItem, pivot) > 0 do
        Dec(high);
      if low <= high then
      begin
        temp := GetItem(low);
        SetItem(low, GetItem(high));
        SetItem(high, temp);
        Inc(low) ;
        Dec(high) ;
      end;
    until low > high;
    if high > lowIndex then
      QuickSort(lowIndex, high);
    if low < high then
      QuickSort(low, highIndex);
  end;
begin
  if (_count = 0) then exit;
  QuickSort(0, _count - 1);
end;

function TList.GetSortedIndex(item: pointer): integer;
var
  compared: integer;
  upper, lower, middle: integer;
  item2: pointer;
begin
  GetSortedIndex := 0;
  if (_count = 0) then exit;
  if (_count = 1) then
  begin
    if (TComparer(_comparer)(item, GetItem(0)) < 0) then
      GetSortedIndex := 0
    else
      GetSortedIndex := 1;
  end;
  upper := _count;
  lower := 0;
  repeat
    middle := (upper + lower) div 2;
    item2 := GetItem(middle);
    compared := TComparer(_comparer)(item, item2);
    if (compared < 0) then
      lower := middle
    else if (compared > 0) then
      upper := middle
    else
    begin
      middle := upper;
      break;
    end;
  until (upper = lower);
  GetSortedIndex := middle;
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

function TList.Where(predicate: TPredicate; var value): PList;
var
  result: PList;
  index: integer;
  item: pointer;
begin
  result := New(PList, Create(''));
  Where := result;
  if (_count = 0) then exit;
  for index := 0 to _count - 1 do
  begin
    item := GetItem(index);
    if predicate(item, value) then
      result^.Add(item);
  end;
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
  if (_count = 0) then exit;
  obj := GetItem(index);
  if (DisposeObjects) then
    Dispose(obj);
  TList.Delete(index);
end;

procedure TObjectList.Clear;
var
  index: integer;
  item: PObject;
begin
  if (DisposeObjects) and (_count > 0) then
  begin
    for index := 0 to _count - 1 do
    begin
    Dispose(GetItem(index), Done);
    end;
  end;
  TList.Clear;
end;

procedure TStack.Init;
begin
  TObjectList.Init;
  DisposeObjects := false;
end;

function TStack.Push(obj: PObject): integer;
begin
  Push := Add(obj);
end;

function TStack.Pop: PObject;
begin
  Pop := nil;
  if (_count = 0) then exit;
  Pop := GetItem(_count - 1);
  Delete(_count - 1);
end;

end.
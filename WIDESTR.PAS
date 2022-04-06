{$O+,F+}
unit WideStr;

interface

uses
  Objects,
  Consts,
  Collects,
  Utils,
  Strings;

type
  PWideString = ^TWideString;
  TWideString = object
    Data: PChar;
    Len: word;
    Capacity: word;
    constructor Create;
    constructor CreateString(st: string);
    constructor CreateBuffer(size: word);
    destructor Done; virtual;
    function ToString: string; virtual;
    function SubString(index: integer; length: byte): string; virtual;
    function GetChar(pos: word): char; virtual;
    procedure SetString(st: string); virtual;
    procedure SetCapacity(newCapacity: word); virtual;
    procedure Append(st: string); virtual;
    procedure Insert(index: integer; st: string); virtual;
    procedure Delete(index: integer);
  end;
  PStringList = ^TStringList;
  TStringList = object(TList)
    procedure Init; virtual;
    function ToString: string; virtual;
    function GetItem(index: integer): PWideString;
    function IndexOf(item: PWideString): integer;
    function Add(item: PWideString): integer;
    procedure Insert(index: integer; item: PWideString);
  end;

implementation

constructor TWideString.Create;
begin
  Data := nil;
  Len := 0;
  Capacity := 0;
end;

function TWideString.GetChar(pos: word): char;
var
  dataPtr: PChar;
begin
  dataPtr := Data;
  Inc(dataPtr, pos);
  GetChar := dataPtr^;
end;

procedure TWideString.SetCapacity(newCapacity: word);
var
  newData: pointer;
  max: word;
  dataSize: word;
begin
  if (Capacity = newCapacity) then exit;
  dataSize := newCapacity;
  GetMem(newData, dataSize);
  FillChar(newData^, dataSize, 0);
  if (newCapacity > 0) and (Data <> nil) then
  begin
    if (newCapacity > Capacity) then
      Move(Data^, NewData^, Capacity)
    else
      Move(Data^, NewData^, newCapacity);
    FreeMem(Data, Capacity);
  end;
  Data := newData;
  Capacity := newCapacity;
  if Len > Capacity then
    Len := Capacity;
end;

constructor TWideString.CreateString(st: string);
begin
  Data := nil;
  Len := 0;
  Capacity := 0;
  SetCapacity(Length(st) * 2);
  SetString(st);
end;

constructor TWideString.CreateBuffer(size: word);
begin
  Len := 0;
  SetCapacity(size);
end;

function TWideString.ToString: string;
var
  result: string;
begin
  Move(Data^, result[1], MinW(Len, 255));
  result[0] := Chr(MinW(Len, 255));
  ToString := result;
end;

procedure TWideString.SetString(st: string);
var
  strPtr: PChar;
begin
  if (Data <> nil) then
    FreeMem(Data, Capacity);
  Data := nil;
  Len := Length(st);
  Capacity := 0;
  SetCapacity(Len);
  strPtr := @st;
  Inc(strPtr, 1);
  Move(strPtr^, Data^, Len);
end;

procedure TWideString.Append(st: string);
var
  strPtr: PChar;
  dataPtr: PChar;
begin
  if (Len + Length(st) > Capacity) then
    SetCapacity(MaxL(Capacity * 2, Capacity + Length(st) * 2));
  strPtr := @st;
  Inc(strPtr, 1);
  dataPtr := Data;
  Inc(dataPtr, Len);
  Move(strPtr^, dataPtr^, Length(st));
  Inc(Len, Length(st));
end;

procedure TWideString.Insert(index: integer; st: string);
var
  strPtr: PChar;
  dataPtr: PChar;
  nextPtr: PChar;
begin
  if (Len + Length(st) > Capacity) then
    SetCapacity(MaxL(Capacity * 2, Capacity + Length(st) * 2));
  strPtr := @st;
  Inc(strPtr, 1);
  dataPtr := Data;
  Inc(dataPtr, index - 1);
  nextPtr := dataPtr;
  Inc(nextPtr, 1);
  Move(dataPtr^, nextPtr^, Len - index + 1);
  Move(strPtr^, dataPtr^, Length(st));
  Inc(Len, Length(st));
end;

procedure TWideString.Delete(index: integer);
var
  dataPtr: PChar;
  nextPtr: PChar;
begin
  if (Len < 1) or (index < 0) or (index > Len - 1) then exit;
  dataPtr := Data;
  Inc(dataPtr, index);
  nextPtr := dataPtr;
  Inc(nextPtr);
  Move(nextPtr^, dataPtr^, Len - index - 1);
  Dec(Len);
end;


function TWideString.SubString(index: integer; length: byte): string;
var
  pos: integer;
  result: string;
  dataPtr: PChar;
begin
  result := '';
  SubString := '';
  if (index < 0) or (length < 1) or (Len = 0) then exit;
  if (index + length > len) then
    length := len - index;
  result[0] := Chr(length);
  dataPtr := Data;
  Inc(dataPtr, index);
  Move(dataPtr^, result[1], length);
  SubString := result;
end;

destructor TWideString.Done;
begin
  if (Data <> nil) then
    FreeMem(Data, Capacity);
end;

procedure TStringList.Init;
begin
  TList.Init;
  TypeName := 'TStringList';
end;

function TStringList.ToString: string;
begin
  TList.Init;
  ToString := TypeName;
end;

function TStringList.GetItem(index: integer): PWideString;
begin
  GetItem := TList.GetItem(index);
end;

function TStringList.IndexOf(item: PWideString): integer;
begin
  IndexOf := TList.IndexOf(item);
end;

function TStringList.Add(item: PWideString): integer;
begin
  TList.Add(item);
end;

procedure TStringList.Insert(index: integer; item: PWideString);
begin
  TList.Insert(index, item);
end;

end.
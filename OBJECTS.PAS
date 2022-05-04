{$I COMPILER.INC}
unit Objects;

interface

uses
  Consts,
  Utils;

type
  PByte = ^byte;
  PWord = ^word;
  PPointer = ^pointer;
  PBaseObject = ^TBaseObject;
  TComparer = function(item1, item2: pointer): integer;
  TPredicate = function(item: pointer; var value): boolean;
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
    constructor Create;
    constructor CreateId(newId: string);
    procedure Init; virtual;
    function ToString: string; virtual;
  end;
  PAllocationError = ^TAllocationError;
  TAllocationError = procedure(var error: TError);
  PPersistent = ^TPersistent;
  TPersistent = object(TObject)
  public
    procedure Init; virtual;
    procedure Assign(var source: TPersistent); virtual;
    procedure AssignTo(var dest: TPersistent); virtual;
  end;

var
  OnAllocationError: PAllocationError;

implementation

uses
  Crt;

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

constructor TObject.CreateId(newId: string);
begin
  Id := NewId;
  Init;
end;

constructor TObject.Create;
begin
  Id := '';
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

procedure TPersistent.Init;
begin
  TObject.Init;
  TypeName := 'TPersistent';
end;

procedure TPersistent.Assign(var source: TPersistent);
begin
end;

procedure TPersistent.AssignTo(var dest: TPersistent);
begin
end;

begin
  OnAllocationError := nil;

end.
{$IFDEF debug}
  {$A+,B-,D+,F+,G+,I+,L+,N+,P+,Q+,R+,S+,V+,X+,Y+}
{$ELSE}
  {$A+,B-,D-,F+,G+,I+,L-,N+,P+,Q-,R-,S-,V+,X+,Y-}
{$ENDIF}
unit Apps;

interface

uses
  Crt,
  Objects;

type
  PApplication = ^TApplication;
  TApplication = object(TObject)
  private
    procedure ProcessKeys; virtual;
    procedure ProcessMouse; virtual;
  public
    Closed: boolean;
    procedure Init; virtual;
    procedure Run; virtual;
    procedure ProcessEvents; virtual;
    procedure Close; virtual;
    destructor Done; virtual;
  end;

implementation

procedure TApplication.Init;
begin
  TObject.Init;
  TypeName := 'TApplication';
  Closed := false;
end;

procedure TApplication.ProcessKeys;
var
  key: char;
begin
  if (KeyPressed) then
  begin
    key := ReadKey;
    if (key = #27) then
      Closed := true;
  end;
end;

procedure TApplication.ProcessMouse;
begin
end;

procedure TApplication.Run;
begin
  repeat
    ProcessEvents;
  until Closed;
end;

procedure TApplication.ProcessEvents;
begin
  ProcessKeys;
  ProcessMouse;
end;

procedure TApplication.Close;
begin
  Closed := true;
end;

destructor TApplication.Done;
begin
  TObject.Done;
  while KeyPressed do ReadKey;
end;

end.
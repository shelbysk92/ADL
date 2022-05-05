{$I COMPILER.INC}
unit GraphIni;

interface

uses
 Objects,
 SvgaDrv,
 GraphDrv;

type
  TGraphDrivers =
  (
    gdVga256,
    gdSVga256
  );
  PGraphicsFactory = ^TGraphicsFactory;
  TGraphicsFactory = object(TBaseObject)
  public
    procedure Init; virtual;
    procedure CreateGraphicsDriver(driverId: TGraphDrivers; var driver: PGraphicsDriver);
  end;

implementation

procedure TGraphicsFactory.Init;
begin
end;

procedure TGraphicsFactory.CreateGraphicsDriver(driverId: TGraphDrivers; var driver: PGraphicsDriver);
begin
  case driverId of
    gdVga256:
    begin
    end;
    gdSVga256:
    begin
      driver := New(PSVgaDriver, Create);
    end;
  end;
end;

end.

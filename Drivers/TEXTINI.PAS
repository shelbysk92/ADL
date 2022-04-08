{$I Compiler.inc}
unit TextIni;

interface

uses
 Objects,
 TextDrv,
 VgaTxDrv;

type
  TTextDrivers =
  (
    tdVga,
    tdAnsi
  );
  PTextDriverFactory = ^TTextDriverFactory;
  TTextDriverFactory = object(TBaseObject)
  public
    procedure Init; virtual;
    procedure CreateTextDriver(driverId: TTextDrivers; var driver);
  end;

implementation

procedure TTextDriverFactory.Init;
begin
end;

procedure TTextDriverFactory.CreateTextDriver(driverId: TTextDrivers; var driver);
begin
  case driverId of
    tdVga: begin
      TVgaTextDriver(driver).Create('VGA Text Driver');
    end;
    tdAnsi: begin
    end;
  end;
end;

end.

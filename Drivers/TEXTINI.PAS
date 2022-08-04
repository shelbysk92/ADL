{$I COMPILER.INC}
unit TextIni;

interface

uses
 Objects,
 TextDrv,
 DirTxDrv,
 SVgaText,
 CrtTxDrv;

type
  TTextDrivers =
  (
    tdDirect,
    tdAnsi,
    tdCrt,
    tdSvga
  );
  PTextDriverFactory = ^TTextDriverFactory;
  TTextDriverFactory = object(TBaseObject)
  public
    procedure Init; virtual;
    procedure CreateTextDriver(driverId: TTextDrivers; var driver: PTextDriver);
  end;

implementation

procedure TTextDriverFactory.Init;
begin
end;

procedure TTextDriverFactory.CreateTextDriver(driverId: TTextDrivers; var driver: PTextDriver);
begin
  case driverId of
    tdDirect: begin
      driver := New(PDirectTextDriver, Create);
    end;
    tdSvga: begin
      driver := New(PSVgaTextDriver, Create);
    end;
    tdAnsi: begin
    end;
    tdCrt: begin
      driver := New(PCrtTextDriver, Create);
    end;
  end;
end;

end.

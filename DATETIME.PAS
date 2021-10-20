{$IFDEF debug}
  {$A+,B-,D+,E+,F+,G+,I+,L+,N+,O-,P+,Q+,R+,S+,V+,X+,Y+}
{$ELSE}
  {$A+,B-,D-,E+,F+,G+,I+,L-,N+,O-,P+,Q-,R-,S-,V+,X+,Y-}
{$ENDIF}
unit DateTime;

interface

uses
  Dos,
  Utils,
  Objects;

type
  TWeekDay =
  (
    Sunday,
    Monday,
    Tuesday,
    Wednesday,
    Thursday,
    Friday,
    Saturday
  );
  TWeekDays = set of TWeekDay;
  TDateTime = object(TBaseObject)
  private
    _ticks: comp; { 100th of second ticks since midnight 1/1/0001 }
    _second, _minute, _hour, _hundredthSecond: byte;
    _month, _day: byte;
    _year: word;
  public
    constructor Create;
    constructor CreateTicks(newTicks: comp);
    constructor CreateDateTime(newYear, newMonth, newDay, newHour, newMinute, newSecond, newHundredthSecond: word);
    constructor CreateDate(newYear, newMonth, newDay: word);
    constructor CreateTime(newHour, newMinute, newSecond, newHundredthSecond: word);
    constructor CreateCurrent;
    constructor CreateCurrentDate;
    constructor CreateCurrentTime;
    procedure SetDate(newYear, newMonth, newDay: word); virtual;
    procedure SetTime(newHour, newMinute, newSecond, newHundredthSecond: word); virtual;
    procedure SetDateTime(newYear, newMonth, newDay, newHour, newMinute, newSecond, newHundredthSecond: word); virtual;
    procedure SetTicks(newTicks: comp); virtual;
    function Ticks: comp; virtual;
    function Day: byte; virtual;
    function Month: byte; virtual;
    function Year: word; virtual;
    function HundredthSecond: byte; virtual;
    function Second: byte; virtual;
    function Minute: byte; virtual;
    function Hour: byte; virtual;
  end;
  TTimeSpan = object(TBaseObject)
  end;
  TTimer = object(TObject)
    StartTime: TDateTime;
    EndTime: TDateTime;
  end;
  TDate = TDateTime;
  TTime = TDateTime;

function DaysInMonth(year: word; month: byte): byte;
function IsLeapYear(year: word): boolean;
function DaysInYear(year: word): word;
function LeapYearsBetween(year1, year2: word): word;
function OneTick: comp;
function OneSecond: comp;
function OneMinute: comp;
function OneHour: comp;
function OneDay: comp;

implementation

constructor TDateTime.Create;
begin
  _ticks := 0;
  _hundredthSecond := 0;
  _second := 0;
  _minute := 0;
  _hour := 0;
  _month := 0;
  _day := 0;
  _year := 0;
end;

constructor TDateTime.CreateTicks(newTicks: comp);
begin
  SetTicks(newTicks);
end;

constructor TDateTime.CreateDateTime(newYear, newMonth, newDay, newHour, newMinute, newSecond, newHundredthSecond: word);
begin
  SetDateTime(newYear, newMonth, newDay, newHour, newMinute, newSecond, newHundredthSecond);
end;

constructor TDateTime.CreateDate(newYear, newMonth, newDay: word);
begin
  SetDate(newYear, newMonth, newDay);
end;

constructor TDateTime.CreateTime(newHour, newMinute, newSecond, newHundredthSecond: word);
begin
  SetTime(newHour, newMinute, newSecond, newHundredthSecond);
end;

constructor TDateTime.CreateCurrent;
var
  newYear, newMonth, newDay, dayOfWeek: word;
  newHour, newMinute, newSecond, newHundredthSecond: word;
begin
  Dos.GetDate(newYear, newMonth, newDay, dayOfWeek);
  Dos.GetTime(newHour, newMinute, newSecond, newHundredthSecond);
  SetDateTime(newYear, newMonth, newDay, newHour, newMinute, newSecond, newHundredthSecond);
end;

constructor TDateTime.CreateCurrentDate;
var
  newYear, newMonth, newDay, dayOfWeek: word;
begin
  Dos.GetDate(newYear, newMonth, newDay, dayOfWeek);
  SetDate(newYear, newMonth, newDay);
end;

constructor TDateTime.CreateCurrentTime;
var
  newHour, newMinute, newSecond, newHundredthSecond: word;
begin
  Dos.GetTime(newHour, newMinute, newSecond, newHundredthSecond);
  SetTime(newHour, newMinute, newSecond, newHundredthSecond);
end;

procedure TDateTime.SetDate(newYear, newMonth, newDay: word);
var
  dayOfWeek, leapYears: word;
begin
  leapYears := LeapYearsBetween(1, newYear - 1);
  _ticks := (newDay - 1) * OneDay;
  _ticks := _ticks + (newMonth - 1) * DaysInMonth(newYear, newMonth) * OneDay;
  _ticks := _ticks + (newYear - 1 - leapYears) * 365 * OneDay;
  _ticks := _ticks + (leapYears) * 366 * OneDay;

  _hundredthSecond := 0;
  _second := 0;
  _minute := 0;
  _hour := 0;
  _month := newMonth;
  _day := newDay;
  _year := newYear;
end;

procedure TDateTime.SetTime(newHour, newMinute, newSecond, newHundredthSecond: word);
begin
  _ticks := newHundredthSecond;
  _ticks := _ticks + newSecond * OneSecond;
  _ticks := _ticks + newMinute * OneMinute;
  _ticks := _ticks + newHour * OneHour;

  _hundredthSecond := newHundredthSecond;
  _second := newSecond;
  _minute := newMinute;
  _hour := newHour;
  _month := 0;
  _day := 0;
  _year := 0;
end;

procedure TDateTime.SetDateTime(newYear, newMonth, newDay, newHour, newMinute, newSecond, newHundredthSecond: word);
var
  dayOfWeek: word;
  leapYears: longint;
begin
  leapYears := LeapYearsBetween(1, newYear - 1);
  _ticks := newHundredthSecond;
  _ticks := _ticks + newSecond * OneSecond;
  _ticks := _ticks + newMinute * OneMinute;
  _ticks := _ticks + newHour * OneHour;
  _ticks := _ticks + (newDay - 1) * OneDay;
  _ticks := _ticks + (newMonth - 1) * DaysInMonth(newYear, newMonth) * OneDay;
  _ticks := _ticks + (newYear - 1 - leapYears) * 365 * OneDay;
  _ticks := _ticks + (leapYears) * 366 * OneDay;

  _hundredthSecond := newHundredthSecond;
  _second := newSecond;
  _minute := newMinute;
  _hour := newHour;
  _month := newMonth;
  _day := newDay;
  _year := newYear;
end;

procedure TDateTime.SetTicks(newTicks: comp);
var
  index: integer;
  currentTicks: comp;
  days: word;
  intTicks: longint;
  h: longint;
begin
  _ticks := newTicks;
  currentTicks := _ticks;
  _year := 1;
  repeat
    days := 365;
    if IsLeapYear(_year + 1) then
      days := 366;
    if (currentTicks - (days * OneDay) <= 0) then
      break;
    currentTicks := currentTicks - (days * OneDay);
    Inc(_year);
  until currentTicks <= 0;
  _month := 1;
  repeat
    if (currentTicks - (DaysInMonth(_year, _month) * OneDay) < 0) then
      break;
    currentTicks := currentTicks - (DaysInMonth(_year, _month) * OneDay);
    Inc(_month);
  until currentTicks <= 0;
  _day := 1;
  repeat
    if (currentTicks - (_day * OneDay) <= 0) then
      break;
    currentTicks := currentTicks - (_day * OneDay);
    Inc(_day);
  until currentTicks <= 0;
  intTicks := round(currentTicks);
  h := intticks div Trunc(OneHour);
  _hour := intTicks mod trunc(OneHour);
  intTicks := intTicks div trunc(OneHour);
  _minute := intTicks mod trunc(OneMinute);
  intTicks := intTicks div trunc(OneMinute);
  _second := intTicks mod trunc(OneSecond);
  intTicks := intTicks div trunc(OneSecond);
  _hundredthSecond := intTicks;
end;

function TDateTime.Ticks: comp;
begin
  Ticks := _ticks;
end;

function TDateTime.Day: byte;
begin
  Day := _day;
end;

function TDateTime.Month: byte;
begin
  Month := _month;
end;

function TDateTime.Year: word;
begin
  Year := _year;
end;

function TDateTime.HundredthSecond: byte;
begin
  HundredthSecond := _hundredthSecond;
end;

function TDateTime.Second: byte;
begin
  Second := _second;
end;

function TDateTime.Minute: byte;
begin
  Minute := _minute;
end;

function TDateTime.Hour: byte;
begin
  Hour := _hour;
end;

function OneTick: comp;
begin
  OneTick := 1;
end;

function OneSecond: comp;
begin
  OneSecond := OneTick * 100;
end;

function OneMinute: comp;
begin
  OneMinute := OneSecond * 60;
end;

function OneHour: comp;
begin
  OneHour := OneMinute * 60;
end;

function OneDay: comp;
begin
  OneDay := OneHour * 24;
end;

function DaysInMonth(year: word; month: byte): byte;
var
  result: byte;
begin
  case month of
    1: result := 31;
    2: result := 28;
    3: result := 31;
    4: result := 30;
    5: result := 31;
    6: result := 30;
    7: result := 31;
    8: result := 31;
    9: result := 30;
    10: result := 31;
    11: result := 30;
    12: result := 31;
  end;
  if IsLeapYear(year) then
    result := 29;
  DaysInMonth := result;
end;

function DaysInYear(year: word): word;
begin
  DaysInYear := 365;
  if (IsLeapYear(year)) then
    DaysInYear := 366;
end;

function IsLeapYear(year: word): boolean;
begin
  IsLeapYear := (year mod 4 = 0) and not ((year mod 100 = 0) and not (year mod 400 = 0));
end;

{ Number of leap years between 1 and year, inclusive }
function CalcLeapYears(year: word): word;
begin
  CalcLeapYears := (year div 4) - (year div 100) + (year div 400);
end;

{ Number of leap years between year1 and year2 inclusive }
function LeapYearsBetween(year1, year2: word): word;
begin
  Dec(year1);
  LeapYearsBetween := CalcLeapYears(year2) - CalcLeapYears(year1);
end;

end.
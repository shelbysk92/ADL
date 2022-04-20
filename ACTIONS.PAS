{$I Compiler.inc}
unit Actions;

interface

uses
  Objects,
  Collects;

type
  PActionEvent = ^TActionEvent;
  TActionEvent = procedure(sender: PControl); far;
  PAction = ^TAction;
  TAction = object(TObject)
  private
  public
    OnExecute: PActionEvent;
  end;
  PActionList = ^TActionList;
  TActionList = object(TObjectList)
  private
  public
  end;

implementation

end.
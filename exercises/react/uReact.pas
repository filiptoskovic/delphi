unit uReact;

interface

uses
  System.SysUtils, System.Generics.Collections;

type


  IObserver = interface(IInvokable)
    procedure Update;
  end;

  IObservable = interface(IInvokable)
    procedure Subscribe(AObserver : IObserver);
    procedure Unsubscribe(AObserver : IObserver);
    procedure Notify;
  end;
  {$M+}
  TCell = class(TInterfacedObject, IObservable)
  private
    FSubscribers : TList<IObserver>;
    FValue : integer;
    procedure DoOnChange;
  protected
    function GetValue : integer; virtual;
    procedure SetValue(const Value: integer);
  public
    procedure Subscribe(AObserver : IObserver);
    procedure Unsubscribe(AObserver : IObserver);
    procedure Notify;
    property Value : integer read GetValue write SetValue;
    constructor Create(AValue : integer = 0);
    destructor Destroy; override;
  end;
  {$M-}
  TCalculation = reference to function(AInputs : TArray<TCell>) : integer;
  {$M+}
  TComputeCell = class (TCell, IObserver)
  private
    FDirty : boolean;
  private
    FInputs : TList<TCell>;
    DoOnCompute : TCalculation;
    function FGetInputs(AInd : integer): TCell;
    procedure FSetInputs(AInd : integer; AValue : TCell);
    procedure SetDoOnCompute(const Value: TCalculation);
  protected
    function GetValue : integer; override;
  public
    property OnCompute : TCalculation read DoOnCompute write SetDoOnCompute;
    property Inputs[i : integer] : TCell read FGetInputs write FSetInputs; default;
    property Value : integer read GetValue write SetValue;
    procedure Update;
    constructor Create(AInputs : TArray<TCell> = nil; ACompute : TCalculation = nil); reintroduce;
    destructor Destroy; override;
  end;
  {$M-}
implementation

{$REGION 'TCell'}

constructor TCell.Create(AValue: integer);
begin
  inherited Create;
  FSubscribers := TList<IObserver>.Create;
  FValue := AValue;
end;

destructor TCell.Destroy;
begin
  FSubscribers.Free;
  inherited;
end;

procedure TCell.DoOnChange;
begin
  Notify;
end;

function TCell.GetValue: integer;
begin
  Result := FValue;
end;

procedure TCell.Notify;
var
  s: IObserver;
begin
  for s in FSubscribers do
    s.Update;
end;

procedure TCell.SetValue(const Value: integer);
begin
  if FValue <> Value then
  begin
    FValue := Value;
    DoOnChange;
  end;
end;

procedure TCell.Subscribe(AObserver: IObserver);
begin
  FSubscribers.Add(AObserver);
end;

procedure TCell.Unsubscribe(AObserver: IObserver);
begin
  FSubscribers.Remove(AObserver);
end;

{$ENDREGION}

{$REGION 'TComputeCell'}

constructor TComputeCell.Create(AInputs: TArray<TCell>; ACompute: TCalculation);
var
  i: Integer;
begin
  Inherited Create;
  FInputs := TList<TCell>.Create;
  FInputs.AddRange(AInputs);
  for i := 0 to FInputs.Count - 1 do
    FInputs[i].Subscribe(self);
  OnCompute := ACompute;
end;

destructor TComputeCell.Destroy;
begin
  FInputs.Free;
  inherited;
end;

function TComputeCell.FGetInputs(AInd: integer): TCell;
begin
  Result := FInputs[AInd];
end;

procedure TComputeCell.FSetInputs(AInd: integer; AValue: TCell);
begin
  if FInputs.Count < AInd + 1 then
    FInputs.Count := AInd + 1;
  FInputs[AInd] := AValue;
end;

function TComputeCell.GetValue: integer;
begin
  if FDirty then
  begin
    FDirty := false;
    Value := DoOnCompute(FInputs.ToArray);
  end;
  Result := FValue;
end;

procedure TComputeCell.SetDoOnCompute(const Value: TCalculation);
begin
  DoOnCompute := Value;
  FDirty := true;
end;

procedure TComputeCell.Update;
begin
  Value := OnCompute(FInputs.ToArray);
end;

{$ENDREGION}

end.

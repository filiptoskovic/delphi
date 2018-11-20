unit uReactTest;

interface
uses
  DUnitX.TestFramework, Delphi.Mocks, uReact;

const
  CanonicalVersion = '2.0.0';

type
  [TestFixture]
  TReactTest = class(TObject)
  private
    Input : TCell;
    Output : TComputeCell;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;

    [Test]
//    [Ignore('Comment the "[Ignore]" statement to run the test')]
    procedure input_cells_have_a_value;

    [Test]
//    [Ignore]
    procedure an_input_cell_value_can_be_set;

    [Test]
//    [Ignore]
    procedure compute_cells_calculate_initial_value;

    [Test]
//    [Ignore]
    procedure compute_cells_take_inputs_in_the_right_order;

    [Test]
//    [Ignore]
    procedure compute_cells_update_value_when_dependencies_are_changed;

    [Test]
//    [Ignore]
    procedure compute_cells_can_depend_on_other_compute_cells;

    [Test]
//    [Ignore]
    procedure callback_cells_only_fire_on_change;


  end;

implementation

uses
  System.SysUtils, System.Generics.Collections;

procedure TReactTest.an_input_cell_value_can_be_set;
begin
  Input := TCell.Create(4);
  Input.Value := 20;
  Assert.AreEqual(20, Input.Value);
end;

procedure TReactTest.callback_cells_only_fire_on_change;
var
  Mock : TMock<TComputeCell>;
begin
  Input := TCell.Create(1);
//   Here im trying to create a mock of TComputeCell
//   Problem is that TComputeCell.Create have 2 arguments, but TMock have none
//   I think there are no constructor constraint on interface
//   I have tried to find workaround but failed
  Mock := TMock<TComputeCell>.Create;

  Mock.Instance.Inputs[0] := Input;
  Mock.Instance.OnCompute := function(AInputs : TArray<TCell>) : integer
    begin
      if AInputs[0].Value < 3 then
        Result := 111
      else
        Result := 222
    end;

  Mock.Setup.Expect.Never.When.Notify;
  Input.Value := 2;
  Mock.Verify;
  Mock.Free;

//  Mock.Setup.Expect.once.When.Notify;
//  Input.Value := 4;
//
//  Mock.Verify;
end;

procedure TReactTest.compute_cells_calculate_initial_value;
begin
  Input := TCell.Create(1);
  Output := TComputeCell.Create([Input],
    function(AInputs : TArray<TCell>) : integer
    begin
      Result := AInputs[0].Value + 1;
    end);
  Assert.AreEqual(2, Output.Value);
end;

procedure TReactTest.compute_cells_can_depend_on_other_compute_cells;
var times_two, times_thirty : TComputeCell;
begin
  Input := TCell.Create(1);
  times_two := TComputeCell.Create([Input],
    function(AInputs : TArray<TCell>) : integer
    begin
      Result := AInputs[0].Value * 2;
    end);

  times_thirty := TComputeCell.Create([Input],
    function(AInputs : TArray<TCell>) : integer
    begin
      Result := AInputs[0].Value * 30;
    end);

  Output := TComputeCell.Create([times_two, times_thirty],
    function(AInputs : TArray<TCell>) : integer
    begin
      Result := AInputs[0].Value + AInputs[1].Value;
    end);

   Assert.AreEqual(32, Output.Value);
   Input.Value := 3;
   Assert.AreEqual(96, Output.Value);
end;

procedure TReactTest.compute_cells_take_inputs_in_the_right_order;
var One, Two : TCell;
begin
  One := TCell.Create(1);
  Two := TCell.Create(2);
  Output := TComputeCell.Create([One, Two],
    function(AInputs : TArray<TCell>) : integer
    begin
      Result := AInputs[0].Value + AInputs[1].Value * 10;
    end);
  Assert.AreEqual(21, Output.Value);
end;

procedure TReactTest.compute_cells_update_value_when_dependencies_are_changed;
begin
  Input := TCell.Create(4);
  Output := TComputeCell.Create([Input],
    function(AInputs : TArray<TCell>) : integer
    begin
      Result := AInputs[0].Value + 1;
    end);
  Input.Value := 3;
  Assert.AreEqual(4, Output.Value);
end;

procedure TReactTest.input_cells_have_a_value;
begin
  Input := TCell.Create(10);
  Assert.AreEqual(10, Input.Value);
end;


procedure TReactTest.Setup;
begin

end;

procedure TReactTest.TearDown;
begin

end;

initialization
  TDUnitX.RegisterTestFixture(TReactTest);
end.

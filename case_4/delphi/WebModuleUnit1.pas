unit WebModuleUnit1;

interface

uses
  System.SysUtils,
  System.Classes,
  System.JSON,
  Web.HTTPApp,
  Data.DB,
  Data.Win.ADODB;

type
  TWebModule1 = class(TWebModule)
    ADOConnection1: TADOConnection;
    ADOQuery1: TADOQuery;
    procedure WebModuleDefaultHandlerAction(Sender: TObject;
      Request: TWebRequest; Response: TWebResponse; var Handled: Boolean);
    procedure WebModuleToursAction(Sender: TObject;
      Request: TWebRequest; Response: TWebResponse; var Handled: Boolean);
    procedure WebModuleTourByIdAction(Sender: TObject;
      Request: TWebRequest; Response: TWebResponse; var Handled: Boolean);
    procedure WebModuleCreateOrderAction(Sender: TObject;
      Request: TWebRequest; Response: TWebResponse; var Handled: Boolean);
  private
    function GetToursJSON: string;
    function GetTourByIdJSON(ATourId: Integer): string;
    function CreateOrder(AClientId, ATourId: Integer): string;
  public
  end;

var
  WebModuleClass: TComponentClass = TWebModule1;

implementation

{$R *.dfm}

function TWebModule1.GetToursJSON: string;
var
  JSONArray: TJSONArray;
  JSONObj: TJSONObject;
begin
  JSONArray := TJSONArray.Create;
  try
    ADOQuery1.Close;
    ADOQuery1.SQL.Text :=
      'SELECT t.tour_id, t.tour_name, t.duration_days, t.base_price, ' +
      't.description, c.country_name ' +
      'FROM Tours t ' +
      'LEFT JOIN Countries c ON t.country_id = c.country_id';
    ADOQuery1.Open;

    while not ADOQuery1.Eof do
    begin
      JSONObj := TJSONObject.Create;
      JSONObj.AddPair('id', TJSONNumber.Create(ADOQuery1.FieldByName('tour_id').AsInteger));
      JSONObj.AddPair('name', ADOQuery1.FieldByName('tour_name').AsString);
      JSONObj.AddPair('country', ADOQuery1.FieldByName('country_name').AsString);
      JSONObj.AddPair('duration_days', TJSONNumber.Create(ADOQuery1.FieldByName('duration_days').AsInteger));
      JSONObj.AddPair('base_price', TJSONNumber.Create(ADOQuery1.FieldByName('base_price').AsFloat));
      JSONObj.AddPair('description', ADOQuery1.FieldByName('description').AsString);

      JSONArray.AddElement(JSONObj);
      ADOQuery1.Next;
    end;

    Result := JSONArray.ToJSON;
  finally
    JSONArray.Free;
    ADOQuery1.Close;
  end;
end;

function TWebModule1.GetTourByIdJSON(ATourId: Integer): string;
var
  JSONObj: TJSONObject;
begin
  JSONObj := TJSONObject.Create;
  try
    ADOQuery1.Close;
    ADOQuery1.SQL.Text :=
      'SELECT t.tour_id, t.tour_name, t.duration_days, t.base_price, ' +
      't.description, c.country_name ' +
      'FROM Tours t ' +
      'LEFT JOIN Countries c ON t.country_id = c.country_id ' +
      'WHERE t.tour_id = :tour_id';

    ADOQuery1.Parameters.ParamByName('tour_id').Value := ATourId;
    ADOQuery1.Open;

    if not ADOQuery1.Eof then
    begin
      JSONObj.AddPair('id', TJSONNumber.Create(ADOQuery1.FieldByName('tour_id').AsInteger));
      JSONObj.AddPair('name', ADOQuery1.FieldByName('tour_name').AsString);
      JSONObj.AddPair('country', ADOQuery1.FieldByName('country_name').AsString);
      JSONObj.AddPair('duration_days', TJSONNumber.Create(ADOQuery1.FieldByName('duration_days').AsInteger));
      JSONObj.AddPair('base_price', TJSONNumber.Create(ADOQuery1.FieldByName('base_price').AsFloat));
      JSONObj.AddPair('description', ADOQuery1.FieldByName('description').AsString);
    end
    else
      JSONObj.AddPair('error', 'Tour not found');

    Result := JSONObj.ToJSON;
  finally
    JSONObj.Free;
    ADOQuery1.Close;
  end;
end;

function TWebModule1.CreateOrder(AClientId, ATourId: Integer): string;
var
  JSONObj: TJSONObject;
  Price: Double;
begin
  JSONObj := TJSONObject.Create;
  try
    ADOQuery1.Close;
    ADOQuery1.SQL.Text :=
      'SELECT base_price FROM Tours WHERE tour_id = :tour_id';
    ADOQuery1.Parameters.ParamByName('tour_id').Value := ATourId;
    ADOQuery1.Open;

    if ADOQuery1.Eof then
    begin
      JSONObj.AddPair('error', 'Tour not found');
      Result := JSONObj.ToJSON;
      Exit;
    end;

    Price := ADOQuery1.FieldByName('base_price').AsFloat;
    ADOQuery1.Close;

    ADOQuery1.SQL.Text :=
      'INSERT INTO Orders (client_id, tour_id, total_price, status) ' +
      'VALUES (:client_id, :tour_id, :total_price, N''новый'')';

    ADOQuery1.Parameters.ParamByName('client_id').Value := AClientId;
    ADOQuery1.Parameters.ParamByName('tour_id').Value := ATourId;
    ADOQuery1.Parameters.ParamByName('total_price').Value := Price;
    ADOQuery1.ExecSQL;

    JSONObj.AddPair('success', 'Order created successfully');
    JSONObj.AddPair('client_id', TJSONNumber.Create(AClientId));
    JSONObj.AddPair('tour_id', TJSONNumber.Create(ATourId));
    JSONObj.AddPair('total_price', TJSONNumber.Create(Price));

    Result := JSONObj.ToJSON;
  except
    on E: Exception do
    begin
      JSONObj.AddPair('error', E.Message);
      Result := JSONObj.ToJSON;
    end;
  end;

  JSONObj.Free;
end;

procedure TWebModule1.WebModuleDefaultHandlerAction(Sender: TObject;
  Request: TWebRequest; Response: TWebResponse; var Handled: Boolean);
begin
  Response.ContentType := 'text/html; charset=UTF-8';
  Response.Content :=
    '<html><body>' +
    '<h1>Tourism Booking System API</h1>' +
    '<p>Доступные методы:</p>' +
    '<ul>' +
    '<li>GET /tours - список туров</li>' +
    '<li>GET /tour/{id} - тур по ID</li>' +
    '<li>POST /order - создание заказа</li>' +
    '</ul>' +
    '</body></html>';

  Handled := True;
end;

procedure TWebModule1.WebModuleToursAction(Sender: TObject;
  Request: TWebRequest; Response: TWebResponse; var Handled: Boolean);
begin
  Response.ContentType := 'application/json; charset=UTF-8';
  Response.Content := GetToursJSON;
  Handled := True;
end;

procedure TWebModule1.WebModuleTourByIdAction(Sender: TObject;
  Request: TWebRequest; Response: TWebResponse; var Handled: Boolean);
var
  TourId: Integer;
  PathValue: string;
begin
  PathValue := StringReplace(Request.PathInfo, '/tour/', '', []);
  TourId := StrToIntDef(PathValue, -1);

  if TourId > 0 then
  begin
    Response.ContentType := 'application/json; charset=UTF-8';
    Response.Content := GetTourByIdJSON(TourId);
  end
  else
  begin
    Response.StatusCode := 400;
    Response.ContentType := 'application/json; charset=UTF-8';
    Response.Content := '{"error":"Invalid tour ID"}';
  end;

  Handled := True;
end;

procedure TWebModule1.WebModuleCreateOrderAction(Sender: TObject;
  Request: TWebRequest; Response: TWebResponse; var Handled: Boolean);
var
  ClientId: Integer;
  TourId: Integer;
begin
  ClientId := StrToIntDef(Request.ContentFields.Values['client_id'], -1);
  TourId := StrToIntDef(Request.ContentFields.Values['tour_id'], -1);

  if (ClientId > 0) and (TourId > 0) then
  begin
    Response.ContentType := 'application/json; charset=UTF-8';
    Response.Content := CreateOrder(ClientId, TourId);
  end
  else
  begin
    Response.StatusCode := 400;
    Response.ContentType := 'application/json; charset=UTF-8';
    Response.Content := '{"error":"Missing client_id or tour_id"}';
  end;

  Handled := True;
end;

end.

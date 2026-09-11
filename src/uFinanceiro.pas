unit uFinanceiro;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, ExtCtrls, ADODB, jpeg;

type
  TfrmFinanceiro = class(TForm)
    pnlTitulo: TPanel;
    lblTitulo: TLabel;
    pnlFiltro: TPanel;
    lblFiltro: TLabel;
    edtMesAno: TEdit;
    btnCalcular: TButton;
    pnlResultados: TPanel;
    lblQ: TLabel;       lblVQ: TLabel;
    lblPV: TLabel;      lblVPV: TLabel;
    lblR: TLabel;       lblVR: TLabel;
    lblSep1: TLabel;
    lblCF: TLabel;      lblVCF: TLabel;
    lblCVU: TLabel;     lblVCVU: TLabel;
    lblCV: TLabel;      lblVCV: TLabel;
    lblCT: TLabel;      lblVCT: TLabel;
    lblSep2: TLabel;
    lblLB: TLabel;      lblVLB: TLabel;
    lblMCU: TLabel;     lblVMCU: TLabel;
    lblPE: TLabel;      lblVPE: TLabel;
    btnVoltar: TButton;
    pnlCarro: TPanel;
    pnlRBruta: TPanel;
    pnlLBruto: TPanel;
    lblResumoVenda: TLabel;
    lblCustos: TLabel;
    lblIndicadores: TLabel;
    Image1: TImage;
    procedure FormShow(Sender: TObject);
    procedure btnCalcularClick(Sender: TObject);
    procedure btnVoltarClick(Sender: TObject);
  private
    procedure Calcular;
    procedure LimparResultados;
  public
    { Public declarations }
  end;

var
  frmFinanceiro: TfrmFinanceiro;

implementation

uses uDM;

{$R *.dfm}

{ Inicializa a tela preenchendo automaticamente o mês atual e limpando os indicadores financeiros }
procedure TfrmFinanceiro.FormShow(Sender: TObject);
begin
  edtMesAno.Text := FormatDateTime('mm/yyyy', Date);
  LimparResultados;
end;

{ Limpa todos os resultados financeiros exibidos na tela, retornando os indicadores ao estado inicial }
procedure TfrmFinanceiro.LimparResultados;
begin
  lblVQ.Caption   := '-';
  lblVPV.Caption  := '-';
  lblVR.Caption   := '-';
  lblVCF.Caption  := '-';
  lblVCVU.Caption := '-';
  lblVCV.Caption  := '-';
  lblVCT.Caption  := '-';
  lblVLB.Caption  := '-';
  lblVMCU.Caption := '-';
  lblVPE.Caption  := '-';
  lblVLB.Font.Color := clWindowText;
end;

{ Aciona o processamento dos cálculos financeiros para o período informado }
procedure TfrmFinanceiro.btnCalcularClick(Sender: TObject);
begin
  Calcular;
end;

{ Realiza o cálculo financeiro do mês informado, obtendo receitas, custos, lucro e indicadores gerenciais }
procedure TfrmFinanceiro.Calcular;
var
  qry: TADOQuery;
  sMesAno: string;
  iMes, iAno: Integer;
  Q: Integer;
  R, CF, CVU, CV, CT, LB, PV, MCU, PE: Double;

  // Verifica se o mês/ano foi informado corretamente
  // Extrai o mês e o ano digitados pelo usuário
begin
  sMesAno := Trim(edtMesAno.Text);
  if Length(sMesAno) <> 7 then
  begin
    ShowMessage('Informe o m'#234's/ano no formato MM/AAAA. Ex: 05/2026');
    edtMesAno.SetFocus;
    Exit;
  end;
  try
    iMes := StrToInt(Copy(sMesAno, 1, 2));
    iAno := StrToInt(Copy(sMesAno, 4, 4));
  except
    ShowMessage('M'#234's/Ano inv'#225'lido.');
    Exit;
  end;

  qry := TADOQuery.Create(nil);
  try
    qry.Connection := dmLavaJato.ADOConnection;
     // Obtém a quantidade de lavagens e a receita total do período
    { Q e R: quantidade e receita do mes }
    qry.SQL.Text :=
      'SELECT COUNT(*) AS Q, ISNULL(SUM(Valor), 0) AS R ' +
      'FROM Lavagens ' +
      'WHERE MONTH(DataLavagem) = :Mes AND YEAR(DataLavagem) = :Ano';
    qry.Parameters.ParamByName('Mes').Value := iMes;
    qry.Parameters.ParamByName('Ano').Value := iAno;
    qry.Open;
    Q := qry.FieldByName('Q').AsInteger;
    R := qry.FieldByName('R').AsFloat;
    qry.Close;

    // Calcula a soma dos custos fixos cadastrados para o mês
    qry.SQL.Text :=
      'SELECT ISNULL(SUM(Valor), 0) AS CF FROM CustoFixo WHERE MesAno = :MesAno';
    qry.Parameters.ParamByName('MesAno').Value := sMesAno;
    qry.Open;
    CF := qry.FieldByName('CF').AsFloat;
    qry.Close;

    // Calcula o custo variável unitário do período
    qry.SQL.Text :=
      'SELECT ISNULL(SUM(ValorUnitario), 0) AS CVU FROM CustoVariavel WHERE MesAno = :MesAno';
    qry.Parameters.ParamByName('MesAno').Value := sMesAno;
    qry.Open;
    CVU := qry.FieldByName('CVU').AsFloat;
    qry.Close;

  finally
    qry.Free;
  end;

  { Calculos (formulas do livro) }
  // Custo Variável Total = custo variável por carro × quantidade de lavagens
  CV  := CVU * Q;                       { CV = CVU x Q           }

  // Custo Total = custos fixos + custos variáveis
  CT  := CF + CV;                       { CT = CF + CV           }

  // Lucro Bruto = receita total - custo total
  LB  := R - CT;                        { LB = R - CT            }

  // Preço médio de venda por lavagem
  if Q > 0 then PV := R / Q else PV := 0;

  // Margem de contribuição unitária
  MCU := PV - CVU;                      { MCU = PV - CVU         }

  // Ponto de equilíbrio (quantidade mínima necessária para cobrir os custos fixos)
  if MCU > 0 then PE := CF / MCU        { PE = CF / MCU          }
  else PE := 0;

  { Exibir resultados }
  lblVQ.Caption   := IntToStr(Q) + ' carros';
  lblVPV.Caption  := 'R$ ' + FloatToStrF(PV,  ffFixed, 10, 2);
  lblVR.Caption   := 'R$ ' + FloatToStrF(R,   ffFixed, 10, 2);
  lblVCF.Caption  := 'R$ ' + FloatToStrF(CF,  ffFixed, 10, 2);
  lblVCVU.Caption := 'R$ ' + FloatToStrF(CVU, ffFixed, 10, 2) + '/carro';
  lblVCV.Caption  := 'R$ ' + FloatToStrF(CV,  ffFixed, 10, 2);
  lblVCT.Caption  := 'R$ ' + FloatToStrF(CT,  ffFixed, 10, 2);
  lblVLB.Caption  := 'R$ ' + FloatToStrF(LB,  ffFixed, 10, 2);
  lblVMCU.Caption := 'R$ ' + FloatToStrF(MCU, ffFixed, 10, 2) + '/carro';
  lblVPE.Caption  := FloatToStrF(PE, ffFixed, 10, 2) + ' carros';

  // Exibe lucro em verde e prejuízo em vermelho
  if LB >= 0 then
    lblVLB.Font.Color := clGreen
  else
    lblVLB.Font.Color := clRed;
end;

// Fecha a tela Financeiro e retorna para a tela anterior
procedure TfrmFinanceiro.btnVoltarClick(Sender: TObject);
begin
    Close;
end;

end.



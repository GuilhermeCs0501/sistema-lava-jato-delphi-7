object dmLavaJato: TdmLavaJato
  OldCreateOrder = False
  OnCreate = DataModuleCreate
  Left = 808
  Top = 340
  Height = 277
  Width = 336
  object ADOConnection: TADOConnection
    ConnectionString = 
      'Provider=SQLOLEDB.1;Integrated Security=SSPI;Persist Security In' +
      'fo=False;Initial Catalog=LavaJato'
    LoginPrompt = False
    Provider = 'SQLOLEDB.1'
    Left = 136
    Top = 16
  end
  object qryLavagens: TADOQuery
    Connection = ADOConnection
    CursorType = ctStatic
    Parameters = <>
    SQL.Strings = (
      'SELECT * FROM Lavagens ORDER BY DataLavagem DESC')
    Left = 40
    Top = 80
  end
  object dsLavagens: TDataSource
    DataSet = qryLavagens
    Left = 40
    Top = 128
  end
  object qryCustoFixo: TADOQuery
    Connection = ADOConnection
    CursorType = ctStatic
    Parameters = <>
    SQL.Strings = (
      'SELECT * FROM CustoFixo ORDER BY Id')
    Left = 136
    Top = 80
  end
  object dsCustoFixo: TDataSource
    DataSet = qryCustoFixo
    Left = 136
    Top = 128
  end
  object qryCustoVariavel: TADOQuery
    Connection = ADOConnection
    CursorType = ctStatic
    Parameters = <>
    SQL.Strings = (
      'SELECT * FROM CustoVariavel ORDER BY Id')
    Left = 232
    Top = 80
  end
  object dsCustoVariavel: TDataSource
    DataSet = qryCustoVariavel
    Left = 232
    Top = 128
  end
end


// 달러에도 붙일거 대비해서 접미사 '원'은 뺌
String formatToKorean(int amount){
  String sign = amount >= 0 ? "":"-";

  amount = amount.abs();
  const int unitMan = 10000;
  const int unitEuk = 100000000;

  if (amount < unitMan || amount > 1e12){
    return "$amount";
  }
  int euk = amount ~/ unitEuk;
  int man = (amount % unitEuk) ~/ unitMan;
  int rest = amount % unitMan;

  String eukString = euk > 0 ? "$euk억" : "";
  String manString = man > 0 ? "$man만" : "";
  String restString = rest == 0 ? "" : "$rest";
  // String restString = (euk == 0 && man == 0) ? "$rest" : "";

  return sign + eukString + manString + restString;
}
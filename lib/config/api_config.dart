

(String, String, String) get_API_credentials(bool isFanar){
  final String fanarApiKey = "fmFrMl3wHnB9SFnb8bzxNFpGCVE18Wcz";
  final String openRouterApiKey = "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";

  final String fanarApiRoute = "https://api.fanar.qa/v1/chat/completions";
  final String openRouterApiRoute = "https://openrouter.ai/api/v1/chat/completions";

  final String fanarModel = "Fanar-Oryx-IVU-1";
  final String openRouterModel = "qwen/qwen-2.5-vl-7b-instruct";
  if(isFanar){
    return (fanarApiKey, fanarApiRoute, fanarModel);
  }else{
    return (openRouterApiKey, openRouterApiRoute, openRouterModel);
  }
}
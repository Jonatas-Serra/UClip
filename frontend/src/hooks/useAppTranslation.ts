import { useTranslation } from 'react-i18next';

export const useAppTranslation = () => {
  const { t, i18n } = useTranslation();
  
  const changeLanguage = (lang: string) => {
    i18n.changeLanguage(lang);
  };
  
  const currentLanguage = i18n.language;
  
  const availableLanguages = [
    { code: 'pt-BR', name: 'Português (Brasil)' },
    { code: 'en', name: 'English' }
  ];
  
  return {
    t,
    changeLanguage,
    currentLanguage,
    availableLanguages,
    i18n
  };
};

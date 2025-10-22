import i18n from 'i18next';
import { initReactI18next } from 'react-i18next';
import ptBR from './locales/pt-BR.json';
import en from './locales/en.json';

// Detectar idioma do sistema
const getDefaultLanguage = (): string => {
  const browserLang = navigator.language || 'en';
  
  // Se o idioma do navegador é português (qualquer variante)
  if (browserLang.startsWith('pt')) {
    return 'pt-BR';
  }
  
  // Padrão: inglês
  return 'en';
};

const resources = {
  'pt-BR': {
    translation: ptBR
  },
  'en': {
    translation: en
  }
};

// Tentar recuperar do localStorage
const savedLanguage = typeof window !== 'undefined' 
  ? localStorage.getItem('uclip-language') 
  : null;

i18n
  .use(initReactI18next)
  .init({
    resources,
    lng: savedLanguage || getDefaultLanguage(),
    fallbackLng: 'en',
    interpolation: {
      escapeValue: false // React já protege contra XSS
    }
  });

// Salvar mudanças de idioma no localStorage
i18n.on('languageChanged', (lng) => {
  if (typeof window !== 'undefined') {
    localStorage.setItem('uclip-language', lng);
  }
});

export default i18n;

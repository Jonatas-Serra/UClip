import React from 'react';
import { useAppTranslation } from '../hooks/useAppTranslation';

export const LanguageSwitcher: React.FC = () => {
  const { t, changeLanguage, currentLanguage, availableLanguages } = useAppTranslation();

  return (
    <div className="flex gap-2 mb-4 p-2 bg-gray-100 rounded-lg">
      <label className="text-sm font-semibold text-gray-700">
        {t('settings.language')}:
      </label>
      <div className="flex gap-1">
        {availableLanguages.map((lang) => (
          <button
            key={lang.code}
            onClick={() => changeLanguage(lang.code)}
            className={`px-3 py-1 text-sm rounded transition-colors ${
              currentLanguage === lang.code
                ? 'bg-blue-500 text-white font-semibold'
                : 'bg-white text-gray-700 border border-gray-300 hover:bg-gray-50'
            }`}
            title={lang.name}
          >
            {lang.code === 'pt-BR' ? '🇧🇷' : '🇺🇸'} {lang.code.split('-')[0].toUpperCase()}
          </button>
        ))}
      </div>
    </div>
  );
};

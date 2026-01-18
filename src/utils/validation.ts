export const validatePassword = (password: string) => {
    if (!password) return { isValid: false, error: "La contraseña es requerida" };

    const upperCount = (password.match(/[A-Z]/g) || []).length;
    const lowerCount = (password.match(/[a-z]/g) || []).length;
    const numberCount = (password.match(/[0-9]/g) || []).length;
    const signCount = (password.match(/[+\-*/]/g) || []).length;
    const symbolCount = (password.match(/[^a-zA-Z0-9+\-*/]/g) || []).length;


    if (upperCount < 2) {
        return { isValid: false, error: "Mínimo 2 letras mayúsculas" };
    }
    if (lowerCount < 2) {
        return { isValid: false, error: "Mínimo 2 letras minúsculas" };
    }
    if (numberCount < 2) {
        return { isValid: false, error: "Mínimo 2 dígitos numéricos" };
    }
    if (signCount < 2) {
        return { isValid: false, error: "Mínimo 2 signos (+, -, *, /)" };
    }
    if (symbolCount < 2) {
        return { isValid: false, error: "Mínimo 2 símbolos (otros caracteres especiales)" };
    }
    if (password.length < 12) {
        return { isValid: false, error: "Mínimo 12 caracteres" };
    }

    return { isValid: true, error: null };
};

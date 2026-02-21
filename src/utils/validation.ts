export const validatePassword = (password: string) => {
    if (!password) return { isValid: false, error: "La contraseña es requerida" };

    const upperCount = (password.match(/[A-Z]/g) || []).length;
    const lowerCount = (password.match(/[a-z]/g) || []).length;
    const numberCount = (password.match(/[0-9]/g) || []).length;

   
    if (upperCount < 1) {
        return { isValid: false, error: "Mínimo 1 letra mayúscula" };
    }
    if (lowerCount < 1) {
        return { isValid: false, error: "Mínimo 1 letra minúscula" };
    }
    if (numberCount < 1) {
        return { isValid: false, error: "Mínimo 1 dígito numérico" };
    }
    if (password.length < 6) {
        return { isValid: false, error: "Mínimo 6 caracteres" };
    }
    return { isValid: true, error: null };
};


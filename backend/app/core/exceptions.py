from fastapi import HTTPException, status #aynı index hatası derleyiciden kaynaklı

# Hazır HTTP hata sınıfları — endpoint'lerde tekrar tekrar yazmamak için

class NotFoundException(HTTPException):
    def __init__(self, detail: str = "Not found"):
        super().__init__(status_code=status.HTTP_404_NOT_FOUND, detail=detail)

class UnauthorizedException(HTTPException):
    def __init__(self, detail: str = "Unauthorized"):
        super().__init__(status_code=status.HTTP_401_UNAUTHORIZED, detail=detail)

class BadRequestException(HTTPException):
    def __init__(self, detail: str = "Bad request"):
        super().__init__(status_code=status.HTTP_400_BAD_REQUEST, detail=detail)

class ForbiddenException(HTTPException):
    def __init__(self, detail: str = "Forbidden"):
        super().__init__(status_code=status.HTTP_403_FORBIDDEN, detail=detail)

class ConflictException(HTTPException):
    # 409 Conflict — aynı güne çift kayıt gibi durumlarda
    def __init__(self, detail: str = "Conflict"):
        super().__init__(status_code=409, detail=detail)
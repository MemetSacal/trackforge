from sqlalchemy.orm import DeclarativeBase # Aynı PyCharm indexleme sorunu, kodu etkilemiyor

class Base(DeclarativeBase):
    # Tum ORM modellerinin miras alacagi temel sinif
    # Spring deki @Entity nin bagli oldugu JPA yapisina benzer
    pass

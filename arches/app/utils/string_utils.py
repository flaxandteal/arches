def str_to_bool(value):
    match value:
        case "y" | "yes" | "t" | "true" | "on" | "1" | "True":
            return True
        case "n" | "no" | "f" | "false" | "off" | "0" | "False":
            return False
    raise ValueError

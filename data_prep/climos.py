import os

from tempfile import NamedTemporaryFile

from cdo import Cdo

from util import d2s

def var_trans(variable):
    # Returns additional variable specific commands
    if variable == 'pr':
        return '-mulc,86400'
    elif variable in ['tasmax', 'tasmin']:
        return '-subc,273.15'

    return ''

def create_climo_file(fp_in, fp_out, t_start, t_end, variable):
    '''
    Generates climatological files from an input file and a selected time range
    Paramenters:
        f_in: input file path
        f_out: output file path
        t_start (datetime.datetime): start date of climo period
        t_end (datetime.datetime): end date of climo period
        variable (str): name of the variable which is being processed
    Requested date range MUST exist in the input file
    '''
    supported_vars = {'tasmin', 'tasmax', 'pr'}

    if variable not in supported_vars:
        raise Exception("Unsupported variable: cant't yet process {}".format(variable))

    # Allow different ops by variable? # op = 'sum' if variable == 'pr' else 'mean'
    op = 'mean'

    cdo = Cdo()
    date_range = '{},{}'.format(d2s(t_start), d2s(t_end))

    if not os.path.exists(os.path.dirname(fp_out)):
        os.makedirs(os.path.dirname(fp_out))


    with NamedTemporaryFile(suffix='.nc') as tempf:
        cdo.seldate(date_range, input=fp_in, output=tempf.name)

        # Add extra postprocessing for specific variables.
        vt = var_trans(variable)

        if 'yr' in fp_in:
            cdo_cmd = '{vt} -tim{op} {fname}'.format(fname=tempf.name, op=op, vt=vt)
        else:
            cdo_cmd = '{vt} -ymon{op} {fname} {vt} -yseas{op} {fname} {vt} -tim{op} {fname}'\
                .format(fname=tempf.name, op=op, vt=vt)

        cdo.copy(input=cdo_cmd, output=fp_out)

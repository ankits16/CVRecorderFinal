# This is a sample Python script.

# Press ⌃R to execute it or replace it with your code.
# Press Double ⇧ to search everywhere for classes, files, tool windows, actions, and settings.
import coremltools as ct
import numpy as np

from coremltools.models.neural_network import datatypes, NeuralNetworkBuilder


def print_hi(name):
    inputs = [('inp', datatypes.Array(1, 1, 4))]
    output = [
        ('x', datatypes.Array(1)),
        ('y', datatypes.Array(1)),
        ('w', datatypes.Array(1)),
        ('h', datatypes.Array(1)),
    ]
    test_builder = NeuralNetworkBuilder(inputs, output, disable_rank5_shape_mapping=True)
    test_builder.add_split_nd(
        'split_coordinates',
        input_name='inp',
        output_names=['x', 'y', 'w', 'h'],
        axis=2,
        split_sizes=[1, 1, 1, 1]
    )
    split_model = ct.models.MLModel(test_builder.spec)
    test_arr = np.arange(4).reshape(1, 1, 4).astype('double')
    print(test_arr.shape)
    print('-------')
    print(test_arr)
    split_model.predict(data={'inp': test_arr})

# Press the green button in the gutter to run the script.
if __name__ == '__main__':
    print_hi('PyCharm')

# See PyCharm help at https://www.jetbrains.com/help/pycharm/
